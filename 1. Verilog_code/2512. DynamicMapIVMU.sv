module DynamicMapIVMU (
    input clk, reset,
    input [7:0] irq,
    input [2:0] map_idx,
    input [2:0] map_irq_num,
    input map_update,
    output reg [31:0] irq_vector,
    output reg irq_valid
);
    reg [31:0] vector_base;
    reg [2:0] irq_map [0:7]; // Maps IRQ number to vector index
    integer i;
    
    initial begin
        vector_base = 32'hA000_0000;
        for (i = 0; i < 8; i = i + 1) irq_map[i] = i[2:0];
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 8; i = i + 1) irq_map[i] <= i[2:0];
            irq_valid <= 0;
        end else if (map_update) begin
            irq_map[map_idx] <= map_irq_num;
        end else begin
            irq_valid <= |irq;
            irq_vector <= vector_base;
            
            for (i = 7; i >= 0; i = i - 1) begin
                if (irq[i]) begin
                    irq_vector <= vector_base + (irq_map[i] << 4);
                end
            end
        end
    end
endmodule