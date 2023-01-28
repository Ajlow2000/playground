struct Node<T> {
    key: T,
    next: Box<Node<T>>,
}

pub struct SinglyLinkedList<T> {
    head: Box<Node<T>>,
    length: usize,
}

impl<T> SinglyLinkedList<T> {
    pub fn new() -> Self {
        Self { head: Box, length: 0 }
    }

    pub fn push(&mut self, key: T) {
        unimplemented!();
    }

    pub fn pop(&mut self) -> Option<T> {
        unimplemented!();
    }

    pub fn get_length(&self) {
        return self.length;
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let result = add(2, 2);
        assert_eq!(result, 4);
    }
}
