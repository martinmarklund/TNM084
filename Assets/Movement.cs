using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Movement : MonoBehaviour
{

    public Camera camera;
    public GameObject gameObject;
    public Vector3 moveSpeed;
    // Start is called before the first frame update
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        moveSpeed = new Vector3(Mathf.Sin(0.5f), Mathf.Sin(0.3f), Mathf.Sin(5)) * 0.005f;
        gameObject.transform.position += moveSpeed;
        camera.transform.position += moveSpeed;
    }
}
