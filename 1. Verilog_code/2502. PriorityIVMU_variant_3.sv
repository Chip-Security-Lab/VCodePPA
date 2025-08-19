//SystemVerilog
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
            irq_valid <= 1'b0;
            // Reset memory
            for (i = 0; i < 16; i = i + 1) begin
                vectors[i] <= 32'h0;
            end
        end else if (prog_we) begin
            // Program memory
            vectors[prog_idx] <= prog_addr;
        end else begin
            // Interrupt handling
            irq_valid <= |irq_in;

            // Optimized priority encoding for isr_addr
            if (irq_in[15]) begin
                isr_addr <= vectors[15];
            end else if (irq_in[14]) begin
                isr_addr <= vectors[14];
            end else if (irq_in[13]) begin
                isr_addr <= vectors[13];
            end else if (irq_in[12]) begin
                isr_addr <= vectors[12];
            end else if (irq_in[11]) begin
                isr_addr <= vectors[11];
            end else if (irq_in[10]) begin
                isr_addr <= vectors[10];
            end else if (irq_in[9]) begin
                isr_addr <= vectors[9];
            end else if (irq_in[8]) begin
                isr_addr <= vectors[8];
            end else if (irq_in[7]) begin
                isr_addr <= vectors[7];
            end else if (irq_in[6]) begin
                isr_addr <= vectors[6];
            end else if (irq_in[5]) begin
                isr_addr <= vectors[5];
            end else if (irq_in[4]) begin
                isr_addr <= vectors[4];
            end else if (irq_in[3]) begin
                isr_addr <= vectors[3];
            end else if (irq_in[2]) begin
                isr_addr <= vectors[2];
            end else if (irq_in[1]) begin
                isr_addr <= vectors[1];
            end else if (irq_in[0]) begin
                isr_addr <= vectors[0];
            end else begin
                // No interrupt active or irq_valid is 0
                isr_addr <= 32'h0;
            end
        end
    end
endmodule