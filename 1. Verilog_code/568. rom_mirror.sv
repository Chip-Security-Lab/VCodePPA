module rom_mirror #(parameter AW=5)(
    input [AW-1:0] addr,
    output [15:0] data
);
    reg [15:0] mem [0:(1<<AW)-1];
    assign data = mem[addr ^ ((1<<AW)-1)]; // 地址镜像
endmodule
