import java.util.Arrays;

class Queue { 
  private int front, rear, capacity; 
  private int queue[]; 

  Queue(int size) { 
    front = rear = 0; 
    capacity = size; 
    queue = new int[capacity];
  } 

  // insert an element into the queue
  void queueEnqueue(int item) { 
    // check if the queue is full
    if (capacity == rear) { 
      this.queueDequeue();
      queue[rear] = item;
      rear++;
    } 

    // insert element at the rear 
    else { 
      queue[rear] = item; 
      rear++;
    } 
    return;
  } 

  //remove an element from the queue
  void queueDequeue() { 
    // check if queue is empty 
    if (front == rear) { 
      System.out.printf("\nQueue is empty\n"); 
      return;
    } 

    // shift elements to the right by one place uptil rear 
    else { 
      for (int i = 0; i < rear - 1; i++) { 
        queue[i] = queue[i + 1];
      } 


      // set queue[rear] to 0
      if (rear < capacity) 
        queue[rear] = 0; 

      // decrement rear 
      rear--;
    } 
    return;
  }
  
  // clear the queue
  void clear() {
    while (this.rear > 0) {
      this.queueDequeue();
    }
  }

  // print queue elements 
  void queueDisplay() 
  { 
    println(Arrays.toString(queue));
  } 

  // print front of queue 
  void queueFront() 
  { 
    if (front == rear) { 
      System.out.printf("Queue is Empty\n"); 
      return;
    } 
    System.out.printf("\nFront Element of the queue: %d", queue[front]); 
    return;
  } 

  // get average of queue
  float getAvg() {
    float res = 0;
    for (int notesAmt : queue) {
      res += (float) notesAmt;
    }
    return res/(rear);
  }

  // get array of queue
  int[] getArray() {
    return Arrays.copyOf(queue, queue.length);
  }
  
  int getLength() {
    return rear;
  }
} 
