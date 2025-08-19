module PriorityIVMU (
    input wire clk, rst,
    input wire [15:0] irq_in,
    input wire [31:0] prog_addr,
    input wire [3:0] prog_idx,
    input wire prog_we,
    output reg [31:0] isr_addr,
    output reg irq_valid
);
    reg [31:0] vectors[15:0];
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            irq_valid <= 0;
            for (i = 0; i < 16; i = i + 1) vectors[i] <= 32'h0;
        end else if (prog_we)
            vectors[prog_idx] <= prog_addr;
        else begin
            irq_valid <= |irq_in;
            isr_addr <= 32'h0;
            for (i = 15; i >= 0; i = i - 1)
                if (irq_in[i]) isr_addr <= vectors[i];
        end
    end
endmodule