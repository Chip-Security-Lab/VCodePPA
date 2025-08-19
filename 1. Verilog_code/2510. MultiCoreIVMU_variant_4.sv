//SystemVerilog
module MultiCoreIVMU (
    input clk,
    input rst,
    input [15:0] irq_src,
    input [1:0] core_sel,
    input [1:0] core_ack,          // Acknowledgment from cores (maps to Ready)
    output reg [31:0] vec_addr [0:3],
    output reg [3:0] core_req           // Request to cores (maps to Valid)
);

    reg [31:0] vector_base [0:3];
    reg [15:0] core_mask [0:3];

    // Signals for buffering masked_irq (high fanout/combinational path)
    wire [15:0] masked_irq_comb [0:3]; // Combinational output from generate block
    reg [15:0] masked_irq_q [0:3];    // Registered version of masked_irq_comb

    // Signal for buffering core_req output (high fanout output)
    reg [3:0] core_req_int; // Internal request signal, registered

    integer i, j; // Loop variables, synthesis handles these

    initial begin
        for (i = 0; i < 4; i = i + 1) begin
            vector_base[i] = 32'h8000_0000 + (i << 8);
            core_mask[i] = 16'hFFFF >> i; // Different mask per core
        end
    end

    genvar g;
    generate
        for (g = 0; g < 4; g = g + 1) begin: gen_masks
            // Combinational logic to calculate masked interrupts
            assign masked_irq_comb[g] = irq_src & ~core_mask[g];
        end
    endgenerate

    // Main sequential logic block
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            core_req_int <= 4'h0; // Reset internal request signal
            for (i = 0; i < 4; i = i + 1) begin
                 vec_addr[i] <= 0;
                 masked_irq_q[i] <= 0; // Reset masked_irq buffer
            end
        end else begin
            // Register the combinational masked_irq_comb
            for (i = 0; i < 4; i = i + 1) begin
                masked_irq_q[i] <= masked_irq_comb[i];
            end

            // Logic for updating core_mask based on core_sel (not part of handshake path requiring buffering)
            if (|core_sel) core_mask[core_sel] <= irq_src;

            // Req-Ack Handshake logic for each core using buffered masked_irq_q
            for (i = 0; i < 4; i = i + 1) begin
                // If core acknowledges, clear the internal request
                if (core_ack[i]) begin
                    core_req_int[i] <= 0;
                end
                // If there's a buffered masked interrupt and no internal request is currently pending
                else if (|masked_irq_q[i] && !core_req_int[i]) begin
                    // Assert the internal request
                    core_req_int[i] <= 1;
                    // Update vector address based on highest priority buffered masked interrupt bit
                    // This logic is combinational based on masked_irq_q, result registered into vec_addr
                    for (j = 15; j >= 0; j = j - 1) begin
                        if (masked_irq_q[i][j]) begin
                            vec_addr[i] <= vector_base[i] + (j << 2);
                            // The original code's loop structure naturally implements priority (highest bit wins)
                            // No break needed as highest j wins
                        end
                    end
                end
                // If request is pending and no ack, keep request asserted.
                // If no interrupt and no request, keep request deasserted.
                // These cases are implicitly handled by the 'else' branches not setting core_req_int
            end
        end
    end

    // Output buffering for core_req
    // This adds a register stage before the output port to buffer the core_req signal
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            core_req <= 4'h0;
        end else begin
            core_req <= core_req_int;
        end
    end

endmodule