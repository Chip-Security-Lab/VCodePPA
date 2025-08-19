//SystemVerilog
module MemMappedIVMU (
    input wire clk, rst_n,
    input wire [7:0] addr,
    input wire [31:0] wdata,
    input wire wr_en, rd_en,
    input wire [15:0] irq_sources,
    output reg [31:0] rdata,
    output reg [31:0] irq_vector,
    output reg irq_valid
);
    reg [31:0] regs [0:17]; // 0-15: Vector table, 16: Mask, 17: Status

    // Pipeline registers for IRQ path (2 stages)
    reg [15:0] irq_masked_q1; // Stage 1 register for masked_irq
    reg valid_h_q1, valid_l_q1; // Stage 1 registers for valid flags
    reg [31:0] vec_h_q1, vec_l_q1; // Stage 1 registers for vector halves

    // Pipeline registers for Read path (1 stage)
    reg [7:0] addr_q1; // Stage 1 register for address
    reg rd_en_q1; // Stage 1 register for read enable

    // Combinational signals for pipeline stages
    wire [15:0] irq_masked; // Stage 0 combinational
    wire [31:0] vec_h_comb, vec_l_comb; // Stage 1 combinational
    wire valid_h_comb, valid_l_comb; // Stage 1 combinational
    wire [31:0] irq_vector_comb; // Stage 2 combinational
    wire irq_valid_comb; // Stage 2 combinational
    wire [31:0] rdata_comb; // Stage 2 combinational (read path)

    integer i; // Used only for initialization loop

    // --- IRQ Path Stage 0: Masking ---
    // Combinational logic depending on inputs and internal registers
    assign irq_masked = irq_sources & ~regs[16][15:0];

    // --- IRQ Path Stage 1: Priority Encoding (based on registered masked_irq) ---
    // Combinational logic depending on Stage 1 registers (irq_masked_q1) and internal registers (regs)
    assign valid_h_comb = |irq_masked_q1[15:8];
    assign valid_l_comb = |irq_masked_q1[7:0];

    assign vec_h_comb = irq_masked_q1[15] ? regs[15] :
                        irq_masked_q1[14] ? regs[14] :
                        irq_masked_q1[13] ? regs[13] :
                        irq_masked_q1[12] ? regs[12] :
                        irq_masked_q1[11] ? regs[11] :
                        irq_masked_q1[10] ? regs[10] :
                        irq_masked_q1[9]  ? regs[9]  :
                        irq_masked_q1[8]  ? regs[8]  :
                        32'h0;

    assign vec_l_comb = irq_masked_q1[7] ? regs[7] :
                        irq_masked_q1[6] ? regs[6] :
                        irq_masked_q1[5] ? regs[5] :
                        irq_masked_q1[4] ? regs[4] :
                        irq_masked_q1[3] ? regs[3] :
                        irq_masked_q1[2] ? regs[2] :
                        irq_masked_q1[1] ? regs[1] :
                        irq_masked_q1[0] ? regs[0] :
                        32'h0;

    // --- IRQ Path Stage 2: Final Selection (based on registered Stage 1 results) ---
    // Combinational logic depending on Stage 2 registers (valid_h_q1, valid_l_q1, vec_h_q1, vec_l_q1)
    assign irq_vector_comb = valid_h_q1 ? vec_h_q1 :
                             valid_l_q1 ? vec_l_q1 :
                             32'h0;

    assign irq_valid_comb = valid_h_q1 | valid_l_q1;

    // --- Read Path Stage 2: Data Access (based on registered address) ---
    // Combinational logic depending on Stage 1 register (addr_q1) and internal registers (regs)
    assign rdata_comb = (addr_q1[4:0] < 18) ? regs[addr_q1[4:0]] : 32'h0;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset regs
            for (i = 0; i < 18; i = i + 1) begin
                regs[i] <= 0;
            end
            // Reset pipeline registers
            irq_masked_q1 <= 0;
            valid_h_q1    <= 0;
            valid_l_q1    <= 0;
            vec_h_q1      <= 0;
            vec_l_q1      <= 0;
            addr_q1       <= 0;
            rd_en_q1      <= 0;
            // Reset outputs
            irq_valid     <= 1'b0;
            rdata         <= 32'h0;
            irq_vector    <= 32'h0;
        end else begin
            // --- Write Path (Stage 0 -> Regs) ---
            // Synchronous write to registers based on current inputs
            if (wr_en) begin
                // Only write to valid addresses 0-17
                if (addr[4:0] < 18) begin
                    regs[addr[4:0]] <= wdata;
                end
            end

            // --- IRQ Path Pipelining ---
            // Stage 0 (comb) -> Stage 1 (reg)
            irq_masked_q1 <= irq_masked;
            // Stage 1 (comb) -> Stage 2 (reg)
            valid_h_q1 <= valid_h_comb;
            valid_l_q1 <= valid_l_comb;
            vec_h_q1   <= vec_h_comb;
            vec_l_q1   <= vec_l_comb;

            // --- Read Path Pipelining ---
            // Stage 0 (inputs) -> Stage 1 (reg)
            // Register address and rd_en
            addr_q1  <= addr;
            rd_en_q1 <= rd_en;

            // --- Update Outputs (from final pipeline stages) ---
            // IRQ outputs from Stage 2 combinational logic
            // Stage 2 (comb) -> Stage 3 (reg - output)
            irq_valid  <= irq_valid_comb;
            irq_vector <= irq_vector_comb;

            // Rdata output from Stage 2 combinational logic, qualified by registered rd_en
            // Stage 2 (comb) -> Stage 3 (reg - output)
            if (rd_en_q1) begin
                 rdata <= rdata_comb;
            end
            // If rd_en_q1 is not active, rdata holds its previous value (FF behavior)

            // --- Update status register (regs[17]) ---
            // Keep original behavior: update with current masked_irq
            // This update is not pipelined relative to masked_irq
            regs[17] <= {16'h0, irq_masked};
        end
    end

endmodule