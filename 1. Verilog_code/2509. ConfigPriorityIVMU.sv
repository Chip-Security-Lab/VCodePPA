module ConfigPriorityIVMU (
    input clk, reset,
    input [7:0] irq_in,
    input [2:0] priority_cfg [0:7],
    input update_pri,
    output reg [31:0] isr_addr,
    output reg irq_out
);
    reg [31:0] vector_table [0:7];
    reg [2:0] priorities [0:7];
    reg [2:0] highest_pri, highest_idx;
    integer i;
    
    initial for (i = 0; i < 8; i = i + 1) begin
        vector_table[i] = 32'h7000_0000 + (i * 64);
        priorities[i] = i;
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            for (i = 0; i < 8; i = i + 1) priorities[i] <= i;
            irq_out <= 0;
        end else if (update_pri) begin
            for (i = 0; i < 8; i = i + 1) priorities[i] <= priority_cfg[i];
        end else begin
            highest_pri <= 3'h7; highest_idx <= 3'h0; irq_out <= 0;
            
            for (i = 0; i < 8; i = i + 1) begin
                if (irq_in[i] && priorities[i] < highest_pri) begin
                    highest_pri <= priorities[i];
                    highest_idx <= i[2:0];
                    irq_out <= 1;
                    isr_addr <= vector_table[i];
                end
            end
        end
    end
endmodule