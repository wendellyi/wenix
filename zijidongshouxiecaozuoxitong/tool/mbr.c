/*
    这个工具用于向软盘镜像写入引导区的512个字节的内容，而不改变其他内容。
    使用方法是
    program boot.bin dst.img
*/
#include <stdio.h>

int main(int args, char* argv[])
{
    char *mbr, *dst;
    char buffer[512];
    int ret;

    if (args != 3)
    {
        printf("the number of args[%d] wrong!\n", args);
        return -1;
    }

    mbr = argv[1];
    dst = argv[2];

    FILE* fp = fopen(mbr, "r");
    if (!fp)
    {
        printf("open file[%s] failed!\n", mbr);
        return -1;
    }

    ret = fread(buffer, 1, sizeof(buffer), fp);
    if (ret != sizeof(buffer))
    {
        printf("fread return[%d]\n", ret);
        return -1;
    }

    fclose(fp);

    fp = fopen(dst, "w");
    if (!fp)
    {
        printf("open file[%s] failed\n", dst);
        return -1;
    }

    ret = fwrite(buffer, 1, sizeof(buffer), fp);
    if (ret != sizeof(buffer))
    {
        printf("fwrite return[%d]\n", ret);
        return -1;
    }

    fclose(fp);
    return 0;    
}
