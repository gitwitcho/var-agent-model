/*
 * Copyright (c) 2011-2014 Gilbert Peffer, Barbara Llacay
 * 
 * The source code and software releases are available at http://code.google.com/p/systemic-risk/
 * 
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
 * in compliance with the License. You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under the License
 * is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
 * or implied. See the License for the specific language governing permissions and limitations under
 * the License.
 */
package info.financialecology.finance.utilities.sandbox;

import java.util.ArrayList;
import java.util.List;

/**
 * This class generates an out of memory error to test the Eclipse Memory Analyser Tool (MAT).
 * <p>
 * For more information on MAT see {@link http://goo.gl/10Wh}.
 * 
 * @author Gilbert Peffer
 *
 */
public class MatHeapDump {

    public static void main(String[] args) {
        ArrayList<String> list = new ArrayList<String>();
        while (true){
            list.add("Generate OutOfMemoryError");
        }
    }
}
