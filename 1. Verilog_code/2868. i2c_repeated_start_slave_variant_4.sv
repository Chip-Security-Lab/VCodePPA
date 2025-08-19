//SystemVerilog
module i2c_repeated_start_slave(
    input wire clk,         // Added system clock for pipeline operation
    input wire rst_n,
    input wire [6:0] self_addr,
    output reg [7:0] data_received,
    output reg repeated_start_detected,
    inout wire sda, scl
);
    // Pipeline stages
    localparam [2:0] IDLE = 3'b000,
                     ADDR = 3'b001,
                     DATA = 3'b010,
                     ACK  = 3'b011;
                     
    // Pipeline control signals
    reg valid_stage1, valid_stage2, valid_stage3;
    
    // Stage 1: Input synchronization and edge detection
    reg sda_in_stage1, scl_in_stage1;
    reg sda_r_stage1, scl_r_stage1, sda_r2_stage1, scl_r2_stage1;
    wire start_condition_stage1;
    
    // Stage 2: Protocol analysis
    reg [2:0] state_stage2;
    reg [7:0] shift_reg_stage2;
    reg [3:0] bit_idx_stage2;
    reg start_detected_stage2;
    
    // Stage 3: Output generation
    reg [7:0] data_out_stage3;
    reg repeated_start_stage3;
    
    // SDA and SCL tri-state control
    reg sda_out, sda_oe;
    reg scl_out, scl_oe;
    
    // Tri-state buffers
    assign sda = sda_oe ? sda_out : 1'bz;
    assign scl = scl_oe ? scl_out : 1'bz;
    
    // Stage 1: Input sampling and edge detection pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_in_stage1 <= 1'b1;
            scl_in_stage1 <= 1'b1;
            sda_r_stage1 <= 1'b1;
            sda_r2_stage1 <= 1'b1;
            scl_r_stage1 <= 1'b1;
            scl_r2_stage1 <= 1'b1;
            valid_stage1 <= 1'b0;
        end else begin
            // Sample inputs
            sda_in_stage1 <= sda;
            scl_in_stage1 <= scl;
            
            // Edge detection registers
            sda_r_stage1 <= sda_in_stage1;
            sda_r2_stage1 <= sda_r_stage1;
            scl_r_stage1 <= scl_in_stage1;
            scl_r2_stage1 <= scl_r_stage1;
            
            // Always validate stage 1 after reset
            valid_stage1 <= 1'b1;
        end
    end
    
    // Stage 1 combinational logic
    wire sda_falling_stage1 = sda_r2_stage1 && !sda_r_stage1;
    wire scl_high_stage1 = scl_r_stage1 && scl_r2_stage1;
    assign start_condition_stage1 = scl_high_stage1 && sda_falling_stage1;
    
    // Stage 2: Protocol analysis pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage2 <= IDLE;
            shift_reg_stage2 <= 8'h00;
            bit_idx_stage2 <= 4'h0;
            start_detected_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
        end else if (valid_stage1) begin
            // Protocol state machine
            case (state_stage2)
                IDLE: begin
                    if (start_condition_stage1) begin
                        state_stage2 <= ADDR;
                        start_detected_stage2 <= 1'b0;
                        bit_idx_stage2 <= 4'h0;
                    end
                end
                ADDR: begin
                    if (start_condition_stage1) begin
                        start_detected_stage2 <= 1'b1;
                        state_stage2 <= ADDR;
                        bit_idx_stage2 <= 4'h0;
                    end else if (scl_r_stage1 && !scl_r2_stage1) begin  // SCL falling edge
                        if (bit_idx_stage2 < 7) begin
                            shift_reg_stage2 <= {shift_reg_stage2[6:0], sda_r_stage1};
                            bit_idx_stage2 <= bit_idx_stage2 + 1'b1;
                        end else begin
                            state_stage2 <= (shift_reg_stage2[7:1] == self_addr) ? DATA : IDLE;
                            bit_idx_stage2 <= 4'h0;
                        end
                    end
                end
                DATA: begin
                    if (start_condition_stage1) begin
                        start_detected_stage2 <= 1'b1;
                        state_stage2 <= ADDR;
                        bit_idx_stage2 <= 4'h0;
                    end else if (scl_r_stage1 && !scl_r2_stage1) begin  // SCL falling edge
                        if (bit_idx_stage2 < 7) begin
                            shift_reg_stage2 <= {shift_reg_stage2[6:0], sda_r_stage1};
                            bit_idx_stage2 <= bit_idx_stage2 + 1'b1;
                        end else begin
                            state_stage2 <= ACK;
                            bit_idx_stage2 <= 4'h0;
                        end
                    end
                end
                ACK: begin
                    if (start_condition_stage1) begin
                        start_detected_stage2 <= 1'b1;
                        state_stage2 <= ADDR;
                        bit_idx_stage2 <= 4'h0;
                    end else if (scl_r_stage1 && !scl_r2_stage1) begin
                        state_stage2 <= DATA;
                    end
                end
                default: state_stage2 <= IDLE;
            endcase
            
            valid_stage2 <= 1'b1;
        end
    end
    
    // Stage 3: Output generation pipeline
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out_stage3 <= 8'h00;
            repeated_start_stage3 <= 1'b0;
            valid_stage3 <= 1'b0;
        end else if (valid_stage2) begin
            // Prepare outputs based on stage 2 results
            if (state_stage2 == ACK) begin
                data_out_stage3 <= shift_reg_stage2;
            end
            
            repeated_start_stage3 <= start_detected_stage2;
            valid_stage3 <= 1'b1;
        end
    end
    
    // Final output registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_received <= 8'h00;
            repeated_start_detected <= 1'b0;
            sda_out <= 1'b1;
            sda_oe <= 1'b0;
            scl_out <= 1'b1;
            scl_oe <= 1'b0;
        end else if (valid_stage3) begin
            // Update actual outputs
            if (state_stage2 == ACK) begin
                data_received <= data_out_stage3;
            end
            
            repeated_start_detected <= repeated_start_stage3;
            
            // SDA control for ACK
            if (state_stage2 == ACK && scl_r_stage1 == 1'b0) begin
                sda_out <= 1'b0;  // ACK
                sda_oe <= 1'b1;   // Drive SDA
            end else begin
                sda_out <= 1'b1;
                sda_oe <= 1'b0;   // Release SDA
            end
        end
    end
endmodule