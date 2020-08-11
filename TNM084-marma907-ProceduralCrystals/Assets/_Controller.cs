using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class _Controller : MonoBehaviour
{

    public Camera m_camera;
    public Material m_mat;

    // Update is called once per frame
    void Update()
    {
        m_mat.SetVector("_WorldSpaceCameraPos", m_camera.transform.position);
    }
}
