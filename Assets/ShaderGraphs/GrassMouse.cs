using UnityEngine;
using UnityEngine.Rendering.Universal;

public class GrassMouse : MonoBehaviour
{

    public Vector3 mouseWorldPos;
    // Start is called once before the first execution of Update after the MonoBehaviour is created
    void Start()
    {
        
    }

    // Update is called once per frame
    void Update()
    {
        mouseWorldPos = Camera.main.ScreenToWorldPoint(Input.mousePosition);
    }
}
