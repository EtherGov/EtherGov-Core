import Image from "next/image";
import { Inter } from "next/font/google";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { Config } from "@/utils/interface";
import { getWalletClient } from "wagmi/actions";
import { createMultisig, findRPCUrl } from "@/shared/safe";
import { useAccount } from "wagmi";

const inter = Inter({ subsets: ["latin"] });

//test multisig
//0x07E9FA5Dce2916e526f7c22fd1f4E630a186602D

export default function Home() {
  const { address } = useAccount();
  const deploy = async () => {
    try {
      const walletClient = await getWalletClient();
      const rpc = await walletClient?.getChainId();
      console.log(rpc);
      if (rpc) {
        const rpcUrl = await findRPCUrl(rpc);
        console.log(rpcUrl);
        const config: Config = {
          RPC_URL: rpcUrl + `/${process.env.INFURA_KEY}`,
          DEPLOY_SAFE: {
            OWNERS: [address as string],
            THRESHOLD: 1,
            SALT_NONCE: Date.now(),
          },
        };
        const result = await createMultisig(config);
        console.log(result);
      } else {
        alert("Please connect your wallet");
      }
    } catch (e) {
      alert(e);
    }
  };

  return (
    <div>
      <div>Create Multisig</div>
      <div>
        <ConnectButton />
      </div>
      <div>
        <button onClick={deploy}>Test</button>
      </div>
    </div>
  );
}
