module rom_cascadable #(parameter STAGES=3)(
    input [7:0] addr,
    output [23:0] data
);
    wire [7:0] stage_out [0:STAGES];
    assign stage_out[0] = addr;
    
    genvar i;
    generate
        for(i=0; i<STAGES; i=i+1) begin : stage
            rom_async #(8,8) u_rom(
                .a(stage_out[i]),
                .dout(stage_out[i+1])
            );
        end
    endgenerate
    
    assign data = {stage_out[1], stage_out[2], stage_out[3]};
endmodule

// Define the missing rom_async module
module rom_async #(parameter AW=8, parameter DW=8)(
    input [AW-1:0] a,
    output [DW-1:0] dout
);
    reg [DW-1:0] mem [0:(1<<AW)-1];
    
    // Initialize memory
    integer i;
    initial begin
        for (i = 0; i < (1<<AW); i = i + 1)
            mem[i] = i & {DW{1'b1}};
    end
    
    assign dout = mem[a];
endmodule