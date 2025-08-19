//SystemVerilog
module rst_sequencer (
    input  wire       clk,
    input  wire       valid,         // Valid signal
    output reg        ready,         // Ready signal
    output reg  [3:0] rst_stages
);
    // Pipeline stage control signals
    reg [2:0] seq_counter;
    reg       seq_active;            // Reset sequence activation flag
    
    // Control path pipeline register
    reg       handshake_detected;
    
    // Data path pipeline registers
    reg [3:0] rst_stages_next;
    
    // Handshake detection logic
    always @(posedge clk) begin
        handshake_detected <= valid && ready;
    end
    
    // Sequence counter control logic
    always @(posedge clk) begin
        if (handshake_detected) begin
            // Initialize sequence on handshake
            seq_counter <= 3'b000;
            seq_active  <= 1'b1;
        end else if (seq_active) begin
            if (seq_counter < 3'b111) begin
                // Advance counter during active sequence
                seq_counter <= seq_counter + 1'b1;
            end else begin
                // Sequence complete
                seq_active <= 1'b0;
            end
        end
    end
    
    // Reset stages data path logic
    always @(posedge clk) begin
        if (handshake_detected) begin
            // Initialize all resets active
            rst_stages_next <= 4'b1111;
            rst_stages     <= 4'b1111;
        end else if (seq_active) begin
            // Release reset stages sequentially
            rst_stages_next <= rst_stages >> 1;
            rst_stages     <= rst_stages_next;
        end
    end
    
    // Ready signal control path
    always @(posedge clk) begin
        if (handshake_detected) begin
            // Not ready during sequence
            ready <= 1'b0;
        end else if (seq_active && (seq_counter == 3'b111)) begin
            // Ready when sequence completes
            ready <= 1'b1;
        end else if (!seq_active) begin
            // Stay ready when idle
            ready <= 1'b1;
        end
    end
    
endmodule