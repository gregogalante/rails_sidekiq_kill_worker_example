# THIS SCRIPT IS A SIMULATION OF A OPERATION RUNNED ON AN EXTERNAL SERVICE.

import time

counter = 0
while counter < 60:
    print("Operation is running...")
    time.sleep(1)
    counter += 1
  
print("Operation finished.")