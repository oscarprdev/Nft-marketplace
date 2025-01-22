'use client';

import { ReactNode, createContext, useRef, useState } from 'react';

export interface ModalProps {
  id: string;
  title: string;
}

type OpenModalInput = {
  content: ReactNode;
  props: ModalProps;
};

export const ModalContext = createContext<{
  open: (input: OpenModalInput) => void;
  close: () => void;
} | null>(null);

export const ModalProvider = ({ children }: { children: ReactNode }) => {
  const modalRef = useRef<HTMLDialogElement>(null);
  const [modalContent, setModalContent] = useState<ReactNode | null>(null);
  const [props, setProps] = useState<ModalProps | null>(null);

  const open = ({ content, props }: { content: ReactNode; props: ModalProps }) => {
    setModalContent(content);
    setProps(props);
    modalRef.current?.showModal();
  };

  const close = () => {
    modalRef.current?.close();

    setTimeout(() => setModalContent(null), 200);
  };

  return (
    <ModalContext.Provider value={{ open, close }}>
      <dialog
        id={`dialog-${props?.id}`}
        ref={modalRef}
        className="h-screen w-screen border">
        <h2>{props?.title}</h2>
        <button onClick={close}>Close</button>
        {modalContent}
      </dialog>
      {children}
    </ModalContext.Provider>
  );
};
