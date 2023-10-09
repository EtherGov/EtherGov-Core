import Image from "next/image";
import { Inter } from "next/font/google";
import { ConnectButton } from "@rainbow-me/rainbowkit";
import { Config } from "@/utils/interface";
import { getWalletClient } from "wagmi/actions";
import { createMultisig, findRPCUrl, getSafeAddress } from "@/shared/safe";
import { useAccount } from "wagmi";
import { useState } from "react";
import { Button, Checkbox, Select } from "@chakra-ui/react";

const inter = Inter({ subsets: ["latin"] });

//test multisig
//0x07E9FA5Dce2916e526f7c22fd1f4E630a186602D

export default function Home() {
  const { address } = useAccount();
  const [safeAddress, setSafeAddress] = useState<string>("");
  const [module, setModule] = useState<boolean>(true);
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
            OWNERS: [
              address as string,
              "0xdb3e0dcFe8208e4CCD9e28b774231d3B426a1882",
              "0xF749EB4F03f74A73Ee398B01209871884Cd1D7a2",
            ],
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

  const getSafe = async () => {
    const data = await getSafeAddress([address as string]);
    setSafeAddress(data);
    console.log(data);
  };

  return (
    <div className="flex flex-col px-[100px]">
      <div>Create Multisig</div>
      <div>
        <ConnectButton />
      </div>
      <div className="my-[10px]">
        <Button onClick={deploy}>Deploy Multisig</Button>
      </div>
      <div>
        <Button onClick={getSafe}>Get Safe Address</Button>
      </div>
      <div>{safeAddress && <p>Safe Address: {safeAddress}</p>}</div>
      <div className="my-[10px]">
        {module ? (
          <div>
            <h1>Create Module</h1>
            <div className="flex flex-col">
              <Checkbox defaultChecked>Cross-Chain Message</Checkbox>
              <Checkbox defaultChecked>Token Bridge</Checkbox>
              <Checkbox defaultChecked>Vote on Transaction</Checkbox>
            </div>
          </div>
        ) : (
          <div></div>
        )}
      </div>
    </div>
  );
}
