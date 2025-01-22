'use client';

import { ReactNode, createContext, useRef, useState } from 'react';

export interface ModalProps {
  id: string;
  title: string;
  data: Record<string, string | number>;
}

export const ModalContext = createContext<{
  open: (modalContent: ReactNode) => void;
  close: () => void;
} | null>(null);

export const ModalProvider = ({ children }: { children: ReactNode }) => {
  const modalRef = useRef<HTMLDialogElement>(null);
  const [modalContent, setModalContent] = useState<ReactNode | null>(null);

  const open = (modalContent: ReactNode) => {
    setModalContent(modalContent);
    modalRef.current?.showModal();
  };

  const close = () => {
    modalRef.current?.close();

    setTimeout(() => setModalContent(null), 200);
  };

  return (
    <ModalContext.Provider value={{ open, close }}>
      <dialog
        ref={modalRef}
        className="h-screen w-screen border">
        <button onClick={close}>Close</button>
        {modalContent}
      </dialog>
      {children}
    </ModalContext.Provider>
  );
};
