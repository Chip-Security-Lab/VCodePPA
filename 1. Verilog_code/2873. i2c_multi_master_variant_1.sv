//SystemVerilog
module i2c_multi_master #(
    parameter ARB_TIMEOUT = 1000  // Arbitration timeout cycles
)(
    input clk,
    input rst,
    input [7:0] tx_data,
    output reg [7:0] rx_data,
    output reg bus_busy,
    inout sda,
    inout scl
);
    // Using conflict detection + timeout mechanism
    reg sda_prev, scl_prev;
    reg sda_prev_pipe; // Pipeline register for sda comparison
    reg [15:0] timeout_cnt;
    reg [15:0] timeout_cnt_next; // Split long adder path
    reg arbitration_lost;
    reg tx_oen;
    reg scl_oen;
    reg [2:0] bit_cnt;
    
    // Intermediate pipeline registers for critical paths
    reg sda_sample, scl_sample;
    reg bus_busy_next;
    reg timeout_reached;
    
    // Split the complex expression evaluation
    always @(*) begin
        timeout_cnt_next = timeout_cnt + 1'b1;
        timeout_reached = (timeout_cnt >= ARB_TIMEOUT-1);
    end
    
    // First pipeline stage - sample inputs
    always @(posedge clk) begin
        if (rst) begin
            sda_sample <= 1'b1;
            scl_sample <= 1'b1;
        end else begin
            sda_sample <= sda;
            scl_sample <= scl;
        end
    end
    
    // Second pipeline stage - main logic
    always @(posedge clk) begin
        if (rst) begin
            bus_busy <= 1'b0;
            arbitration_lost <= 1'b0;
            sda_prev <= 1'b1;
            scl_prev <= 1'b1;
            sda_prev_pipe <= 1'b1;
            timeout_cnt <= 16'h0000;
            tx_oen <= 1'b1;
            scl_oen <= 1'b1;
            bit_cnt <= 3'b000;
            bus_busy_next <= 1'b0;
        end else begin
            // Split arbitration detection logic
            sda_prev <= sda_sample;
            scl_prev <= scl_sample;
            sda_prev_pipe <= sda_prev;
            
            // Pipeline the arbitration lost detection
            if (sda_sample != sda_prev && bus_busy) begin
                arbitration_lost <= 1'b1;
            end
            
            // Timeout counter with pipelined logic
            if (bus_busy) begin
                timeout_cnt <= timeout_cnt_next;
                bus_busy_next <= timeout_reached ? 1'b0 : bus_busy;
            end else begin
                bus_busy_next <= bus_busy;
            end
            
            // Update bus state in next cycle
            bus_busy <= bus_busy_next;
            
            // Conditionally update control signals
            if (timeout_reached && bus_busy) begin
                tx_oen <= 1'b1;
                scl_oen <= 1'b1;
            end
        end
    end

    // Data path control with sequential logic
    reg [2:0] bit_cnt_masked;
    reg tx_bit_value;
    
    always @(posedge clk) begin
        if (rst) begin
            bit_cnt_masked <= 3'b000;
            tx_bit_value <= 1'b1;
        end else begin
            bit_cnt_masked <= bit_cnt;
            tx_bit_value <= tx_data[bit_cnt];
        end
    end
    
    // Tri-state control with pipelined signals
    assign sda = (tx_oen) ? tx_bit_value : 1'bz;
    assign scl = (scl_oen) ? 1'b0 : 1'bz;
endmodule