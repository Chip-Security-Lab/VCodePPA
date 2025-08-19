//SystemVerilog
module i2c_power_slave(
    input rst_b,
    input power_mode,
    input [6:0] dev_addr,
    output reg [7:0] data_out,
    output reg wake_up,
    inout sda, scl
);
    // State and register declarations
    reg [2:0] state;
    reg [7:0] shift_reg;
    reg [3:0] bit_counter;
    reg sda_prev, scl_prev;
    reg addr_match;
    reg sda_fall_detected;
    
    // Buffered signals for high fanout reduction
    reg rst_b_buf1, rst_b_buf2;
    reg scl_buf1, scl_buf2;
    reg sda_buf;
    reg [6:0] dev_addr_buf;
    
    // Input buffering to reduce fanout
    always @(*) begin
        rst_b_buf1 = rst_b;
        rst_b_buf2 = rst_b;
        scl_buf1 = scl;
        scl_buf2 = scl;
        sda_buf = sda;
        dev_addr_buf = dev_addr;
    end
    
    // Pre-compute start condition logic to reduce critical path
    always @(posedge scl_buf1 or negedge rst_b_buf1) begin
        if (!rst_b_buf1) begin
            sda_prev <= 1'b1;
            sda_fall_detected <= 1'b0;
        end else begin
            sda_prev <= sda_buf;
            // Detect SDA falling edge while SCL is high (start condition)
            sda_fall_detected <= sda_prev && !sda_buf;
        end
    end
    
    // Split state machine to balance paths and improve timing
    reg wake_up_pre;
    reg addr_match_pre;
    
    // First stage - handle wake_up_pre and address matching pre-computation
    always @(posedge scl_buf1 or negedge rst_b_buf1) begin
        if (!rst_b_buf1) begin
            wake_up_pre <= 1'b0;
            addr_match_pre <= 1'b0;
        end else begin
            // Wake-up logic - separated to balance paths
            if (!power_mode && sda_fall_detected) begin
                wake_up_pre <= 1'b1;
            end
            
            // Address matching logic pre-computation
            if (state == 3'b001 && bit_counter == 4'd7) begin
                addr_match_pre <= (shift_reg[7:1] == dev_addr_buf);
            end
        end
    end
    
    // Second stage - handle main state machine with reduced fanout
    always @(posedge scl_buf2 or negedge rst_b_buf2) begin
        if (!rst_b_buf2) begin
            state <= 3'b000;
            wake_up <= 1'b0;
            addr_match <= 1'b0;
            bit_counter <= 4'd0;
            shift_reg <= 8'd0;
        end else begin
            // Register transfer for wake-up signal to improve timing
            wake_up <= wake_up_pre;
            
            // Register transfer for address match signal
            addr_match <= addr_match_pre;
            
            // State transition logic would go here
            // Additional logic for bit counter and shift register would be here
        end
    end
    
    // Add a third stage for data_out to further balance paths
    always @(posedge scl_buf2 or negedge rst_b_buf2) begin
        if (!rst_b_buf2) begin
            data_out <= 8'd0;
        end else if (addr_match && state == 3'b010) begin
            // Data output logic would be here
            data_out <= shift_reg;
        end
    end
endmodule