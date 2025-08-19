//SystemVerilog
module eth_packet_counter #(
    parameter COUNTER_WIDTH = 32
) (
    input  wire                      clk,
    input  wire                      reset_n,
    input  wire                      packet_valid,
    input  wire                      packet_error,
    output reg  [COUNTER_WIDTH-1:0] good_packets,
    output reg  [COUNTER_WIDTH-1:0] error_packets,
    output reg  [COUNTER_WIDTH-1:0] total_packets
);
    // Stage 1: Input Registration
    reg packet_valid_stage1, packet_error_stage1, reset_n_stage1;
    
    always @(posedge clk) begin
        packet_valid_stage1 <= packet_valid;
        packet_error_stage1 <= packet_error;
        reset_n_stage1     <= reset_n;
    end
    
    // Stage 2: Increment Signal Generation
    reg packet_valid_stage2, packet_error_stage2, reset_n_stage2;
    reg increment_good_stage2, increment_error_stage2, increment_total_stage2;
    
    always @(posedge clk) begin
        // Pass along registered signals to reduce fanout
        packet_valid_stage2 <= packet_valid_stage1;
        packet_error_stage2 <= packet_error_stage1;
        reset_n_stage2     <= reset_n_stage1;
        
        // Generate increment signals with reduced logic depth
        increment_total_stage2 <= packet_valid_stage1;
        increment_good_stage2  <= packet_valid_stage1 & ~packet_error_stage1;
        increment_error_stage2 <= packet_valid_stage1 & packet_error_stage1;
    end
    
    // Stage 3: Counter Update Logic - Distributed across multiple always blocks
    // for better optimization opportunities
    
    // Good Packets Counter
    always @(posedge clk) begin
        if (!reset_n_stage1) begin
            good_packets <= {COUNTER_WIDTH{1'b0}};
        end else if (increment_good_stage2) begin
            good_packets <= good_packets + 1'b1;
        end
    end
    
    // Error Packets Counter
    always @(posedge clk) begin
        if (!reset_n_stage2) begin
            error_packets <= {COUNTER_WIDTH{1'b0}};
        end else if (increment_error_stage2) begin
            error_packets <= error_packets + 1'b1;
        end
    end
    
    // Total Packets Counter
    always @(posedge clk) begin
        if (!reset_n_stage1) begin
            total_packets <= {COUNTER_WIDTH{1'b0}};
        end else if (increment_total_stage2) begin
            total_packets <= total_packets + 1'b1;
        end
    end
    
endmodule