/*
 *                            _/                                                    _/   
 *       _/_/_/      _/_/    _/  _/    _/    _/_/_/    _/_/    _/_/_/      _/_/_/  _/    
 *      _/    _/  _/    _/  _/  _/    _/  _/    _/  _/    _/  _/    _/  _/    _/  _/     
 *     _/    _/  _/    _/  _/  _/    _/  _/    _/  _/    _/  _/    _/  _/    _/  _/      
 *    _/_/_/      _/_/    _/    _/_/_/    _/_/_/    _/_/    _/    _/    _/_/_/  _/       
 *   _/                            _/        _/                                          
 *  _/                        _/_/      _/_/                                             
 *                                                                                       
 * POLYGONAL - A HAXE LIBRARY FOR GAME DEVELOPERS
 * Copyright (c) 2009 Michael Baczynski, http://www.polygonal.de
 *
 * Permission is hereby granted, free of charge, to any person obtaining
 * a copy of this software and associated documentation files (the
 * "Software"), to deal in the Software without restriction, including
 * without limitation the rights to use, copy, modify, merge, publish,
 * distribute, sublicense, and/or sell copies of the Software, and to
 * permit persons to whom the Software is furnished to do so, subject to
 * the following conditions:
 * The above copyright notice and this permission notice shall be
 * included in all copies or substantial portions of the Software.
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 * NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
 * LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
 * OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
 * WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */
import de.polygonal.ds.DA;
import de.polygonal.ds.Graph;
import de.polygonal.ds.Heap;

class GraphAStar<T>
{
	var _graph:Graph<T>;
	
	var _que:Heap<Waypoint<T>>;
	
	public function new(graph:Graph<T>)
	{
		_graph = graph;
		_que = new Heap<Waypoint<T>>();
	}
	
	public function free():Void
	{
		_graph.free();
		_que.free();
		
		_graph = null;
		_que = null;
	}
	
	/**
	 * Finds the shortest path from source to target and stores the result in path.
	 * @return True if a path from source to target exists.
	 */
	public function find(graph:Graph<T>, source:Waypoint<T>, target:Waypoint<T>, path:DA<Waypoint<T>>):Bool
	{
		var pathExists = false;
		
		//reset search
		var walker = graph.getNodeList();
		while (walker != null)
		{
			//reset node
			cast(walker, Waypoint<Dynamic>).reset();
			walker = walker.next;
		}
		
		var q = _que;
		
		//reset queue
		q.clear();
		
		//enqueue starting node
		q.add(source);
		
		//while there are waypoints in the queue...
		while (q.size() > 0)
		{
			//grab the next waypoint off the queue and process it
			var node1 = q.pop();
			node1.onQue = false;
			
			//make sure the waypoint wasn't visited before (can be visited multiple times)
			if (node1.marked) continue;
			
			//mark node as processed
			node1.marked = true;
			
			//exit if the target node has been found
			if (node1 == target)
			{
				pathExists = true;
				break;
			}
			
			//visit all connected nodes (denoted as node2, node2)
			var arc = node1.arcList;
			while (arc != null)
			{
				//the node our arc is pointing at
				var node2:Waypoint<T> = cast arc.node;
				
				//skip marked nodes
				if (node2.marked)
				{
					arc = arc.next;
					continue;
				}
				
				//compute accumulated distance to get from the current waypoint (1) to the next waypoint (2)
				var distance = node1.distance + node1.distanceTo(node2) * arc.cost;
				
				//node has been processed before ?
				if (node2.parent != null)
				{
					//distance has been calculated before so check if new distance is shorter
					if (distance < node2.distance)
					{
						//switch to shorter path ('edge relaxation')
						node2.parent = node1;
						node2.distance = distance;
					}
					else
					{
						//new distance > existing distance, skip
						arc = arc.next;
						continue;
					}
				}
				else
				{
					//first time of being added to the queue - setup parent and distance
					node2.parent = node1;
					node2.distance = distance;
				}
				
				//compute A* heuristics
				var heuristics = node2.distanceTo(target) + distance;
				
				//waypoints closest to the source node are processed first
				node2.heuristic = heuristics;
				
				//add to the search frontier
				if (!node2.onQue)
				{
					node2.onQue = true;
					q.add(node2);
				}
				
				arc = arc.next;
			}
		}
		
		if (pathExists)
		{
			//trace the path by working back through the parents
			//from the target node to the source node
			var walker = target;
			while (walker != source)
			{
				path.pushBack(walker);
				walker = cast walker.parent;
			}
			
			path.pushBack(source);
			path.reverse();
		}
		
		return pathExists;
	}
}