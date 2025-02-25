<?php

declare(strict_types=1);

namespace App\Controller;

use Symfony\Bundle\FrameworkBundle\Controller\AbstractController;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\Routing\Attribute\Route;

final class HomeController extends AbstractController
{
    #[Route('/', methods: [Request::METHOD_GET])]
    public function index(Request $request): Response
    {
        return $this->render('index.html.twig', ['values' => [
            'acceptable_content_types' => \implode(',', $request->getAcceptableContentTypes()),
            'clientIp' => $request->getClientIp(),
            'cpu' => $this->getCPU(),
            'has_previous_session' => $request->hasPreviousSession() ? 'Yes' : 'No',
            'host' => $request->getHost(),
            'host_name' => gethostname(),
            'server_ip' => $request->server->get('SERVER_ADDR'),
            'server_software' => $request->server->get('SERVER_SOFTWARE'),
            'is_from_trusted_proxy' => $request->isFromTrustedProxy() ? 'Yes' : 'No',
            'is_secure' => $request->isSecure() ? 'Yes' : 'No',
            'languages' => implode(',', $request->getLanguages()),
            'locale' => $request->getLocale(),
            'memory_limit' => ini_get('memory_limit'),
            'num_cpus' => $this->getNumCpus() ?? '?',
            'php_sapi' => php_sapi_name(),
            'preferred_language' => $request->getPreferredLanguage(),
            'protocol_version' => $request->getProtocolVersion(),
            'scheme' => $request->getScheme(),
        ]]);
    }

    #[Route('/phpinfo', methods: [Request::METHOD_GET])]
    public function phpinfo(): Response
    {
        ob_start();
        phpinfo();
        $phpInfo = ob_get_contents();
        ob_end_clean();
        return new Response($phpInfo);
    }

    private function getCPU(): string
    {
        $name = php_uname('m');
        // workaround bug
        if (strlen($name) > 20 and stripos($name, 'linux') !== false) {
            $name = `uname -m`;
        }
        return trim($name);
    }

    private function getNumCpus(): ?int
    {
        try {
            $cpuInfo = file_get_contents('/proc/cpuinfo');
            preg_match_all('/^processor/m', $cpuInfo, $matches);

            return count($matches[0]);
        } catch (\Throwable) {
            return null;
        }
    }

    #[Route('/healthz', methods: [Request::METHOD_GET], stateless: true)]
    public function healthz(): Response
    {
        return new Response();
    }
}
