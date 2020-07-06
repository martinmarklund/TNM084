using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Controller : MonoBehaviour
{
    public new GameObject gameObject;
    public float rotationSpeed = 25.0f;

    void Update()
    {
        if(Input.GetKey("space"))
            gameObject.transform.Rotate(0.0f,rotationSpeed*Time.deltaTime,0.0f,Space.World);
    }
}
