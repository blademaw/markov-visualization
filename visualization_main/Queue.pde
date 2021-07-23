/*

 Created by:
 Jack
 On Date:
 5-Jul-2021
 Last updated on:
 23-Jul-2021
 Purpose & intent:
 * act as class for individual piano key
 */

import java.util.Arrays;

/**
 * Class for a queue data structure
 */
class Queue { 
  private int front, rear, capacity; 
  private int queue[]; 

  Queue(int size) { 
    front = rear = 0; 
    capacity = size; 
    queue = new int[capacity];
  } 

  /**
   * Function to insert an element into the queue
   */
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

  /**
   * Function to remove an element from the queue
   */
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

  /**
   * Function to clear the queue
   */
  void clear() {
    while (this.rear > 0) {
      this.queueDequeue();
    }
  }

  /**
   * Function to print the queue
   */
  void queueDisplay() 
  { 
    println(Arrays.toString(queue));
  }

  /**
   * Function to get the average of the queue
   */
  float getAvg() {
    float res = 0;
    for (int notesAmt : queue) {
      res += (float) notesAmt;
    }
    return res/(rear);
  }

  /**
   * Function to return the array of the queue
   */
  int[] getArray() {
    return Arrays.copyOf(queue, queue.length);
  }

  /**
   * Function to get the length of the queue
   */
  int getLength() {
    return rear;
  }
} 
