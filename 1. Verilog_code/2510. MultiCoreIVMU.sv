module MultiCoreIVMU (
    input clk, rst,
    input [15:0] irq_src,
    input [1:0] core_sel,
    input [1:0] core_ack,
    output reg [31:0] vec_addr [0:3],
    output reg [3:0] core_irq
);
    reg [31:0] vector_base [0:3];
    reg [15:0] core_mask [0:3];
    wire [15:0] masked_irq [0:3];
    integer i, j;
    
    initial begin
        for (i = 0; i < 4; i = i + 1) begin
            vector_base[i] = 32'h8000_0000 + (i << 8);
            core_mask[i] = 16'hFFFF >> i; // Different mask per core
        end
    end
    
    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin: gen_masks
            assign masked_irq[g] = irq_src & ~core_mask[g];
        end
    endgenerate
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            core_irq <= 4'h0;
            for (i = 0; i < 4; i = i + 1) vec_addr[i] <= 0;
        end else begin
            if (|core_sel) core_mask[core_sel] <= irq_src;
            
            for (i = 0; i < 4; i = i + 1) begin
                if (core_ack[i]) core_irq[i] <= 0;
                else if (|masked_irq[i] && !core_irq[i]) begin
                    core_irq[i] <= 1;
                    for (j = 15; j >= 0; j = j - 1) begin
                        if (masked_irq[i][j])
                            vec_addr[i] <= vector_base[i] + (j << 2);
                    end
                end
            end
        end
    end
endmodule