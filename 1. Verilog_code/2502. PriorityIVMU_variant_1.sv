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

    // Registered inputs to reduce input-to-flop path delay
    reg [15:0] irq_in_r;
    reg [31:0] prog_addr_r;
    reg [3:0] prog_idx_r;
    reg prog_we_r;

    // Combinatorial logic now operates on registered inputs
    wire irq_valid_comb;
    wire [3:0] winning_index_comb;
    wire [31:0] isr_addr_comb;

    // Combinatorial logic using registered inputs
    assign irq_valid_comb = |irq_in_r;

    // Priority encoder: Find the index of the highest set bit in irq_in_r
    // This structure synthesizes into a tree of multiplexers
    assign winning_index_comb =
        irq_in_r[15] ? 4'd15 :
        irq_in_r[14] ? 4'd14 :
        irq_in_r[13] ? 4'd13 :
        irq_in_r[12] ? 4'd12 :
        irq_in_r[11] ? 4'd11 :
        irq_in_r[10] ? 4'd10 :
        irq_in_r[9]  ? 4'd9  :
        irq_in_r[8]  ? 4'd8  :
        irq_in_r[7]  ? 4'd7  :
        irq_in_r[6]  ? 4'd6  :
        irq_in_r[5]  ? 4'd5  :
        irq_in_r[4]  ? 4'd4  :
        irq_in_r[3]  ? 4'd3  :
        irq_in_r[2]  ? 4'd2  :
        irq_in_r[1]  ? 4'd1  :
        irq_in_r[0]  ? 4'd0  :
        4'd0; // Default when no interrupt (irq_valid_comb will be 0)

    // Select the ISR address based on the winning index from registered inputs
    // If no interrupt is valid, the address should be 0, matching original behavior
    // This synthesizes into a multiplexer selecting from the 'vectors' array
    assign isr_addr_comb = irq_valid_comb ? vectors[winning_index_comb] : 32'h0;

    // Sequential logic for input registration, memory write and output registration
    always @(posedge clk) begin
        if (rst) begin
            // Synchronous reset for inputs, outputs and memory
            irq_in_r <= '0;
            prog_addr_r <= '0;
            prog_idx_r <= '0;
            prog_we_r <= 1'b0;

            irq_valid <= 1'b0;
            isr_addr <= 32'h0;
            for (i = 0; i < 16; i = i + 1) begin
                vectors[i] <= 32'h0;
            end
        end else begin
            // Register inputs on the clock edge
            irq_in_r <= irq_in;
            prog_addr_r <= prog_addr;
            prog_idx_r <= prog_idx;
            prog_we_r <= prog_we;

            // Memory write logic uses registered inputs
            // Write happens one cycle after prog_we, prog_addr, prog_idx are valid at the input pins
            if (prog_we_r) begin
                vectors[prog_idx_r] <= prog_addr_r;
            end else begin // !prog_we_r
                // Synchronous update of outputs with combinatorial results (based on registered inputs)
                // Outputs are updated one cycle after irq_in is registered and prog_we_r is low
                irq_valid <= irq_valid_comb;
                isr_addr <= isr_addr_comb;
            end
        end
    end

endmodule