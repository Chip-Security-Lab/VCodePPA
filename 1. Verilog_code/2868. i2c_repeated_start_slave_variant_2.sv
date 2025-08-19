//SystemVerilog
module i2c_repeated_start_to_axis (
    // Clock and reset
    input  wire        aclk,
    input  wire        aresetn,
    
    // I2C interface
    input  wire [6:0]  self_addr,
    inout  wire        sda, 
    inout  wire        scl,
    
    // AXI-Stream master interface
    output wire [7:0]  m_axis_tdata,
    output wire        m_axis_tvalid,
    input  wire        m_axis_tready,
    output wire        m_axis_tlast
);
    // State definitions
    localparam IDLE    = 3'b000;
    localparam ADDR    = 3'b001;
    localparam DATA    = 3'b010;
    localparam TRANSFER = 3'b011;
    
    reg [2:0] state, next_state;
    reg sda_r, scl_r, sda_r2, scl_r2;
    reg [7:0] shift_reg;
    reg [3:0] bit_idx;
    
    // Data flow control
    reg [7:0] data_received_reg;
    reg repeated_start_detected_reg;
    reg data_valid_reg;
    reg transfer_complete_reg;
    
    // Split start_condition signal to reduce fanout
    reg start_condition_buf1, start_condition_buf2;
    wire start_condition = scl_r && sda_r2 && !sda_r;
    wire stop_condition = scl_r && !sda_r2 && sda_r;
    
    // I2C line control
    reg sda_out;
    reg sda_oen; // Output enable (active low)
    
    assign sda = sda_oen ? 1'bz : sda_out;
    
    // AXI-Stream interface connections
    assign m_axis_tdata  = data_received_reg;
    assign m_axis_tvalid = data_valid_reg;
    assign m_axis_tlast  = repeated_start_detected_reg;
    
    // Register synchronization to prevent metastability
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            sda_r <= 1'b1;
            sda_r2 <= 1'b1;
            scl_r <= 1'b1;
            scl_r2 <= 1'b1;
        end else begin
            sda_r <= sda;
            sda_r2 <= sda_r;
            scl_r <= scl;
            scl_r2 <= scl_r;
        end
    end
    
    // Buffer for start_condition to reduce fanout
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            start_condition_buf1 <= 1'b0;
            start_condition_buf2 <= 1'b0;
        end else begin
            start_condition_buf1 <= start_condition;
            start_condition_buf2 <= start_condition_buf1;
        end
    end
    
    // I2C state machine
    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            state <= IDLE;
            next_state <= IDLE;
            repeated_start_detected_reg <= 1'b0;
            data_received_reg <= 8'h00;
            shift_reg <= 8'h00;
            bit_idx <= 4'h0;
            sda_out <= 1'b1;
            sda_oen <= 1'b1;
            data_valid_reg <= 1'b0;
            transfer_complete_reg <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    if (start_condition) begin
                        state <= ADDR;
                        bit_idx <= 4'h0;
                        repeated_start_detected_reg <= 1'b0;
                        data_valid_reg <= 1'b0;
                    end
                end
                
                ADDR: begin
                    if (start_condition_buf2) begin
                        repeated_start_detected_reg <= 1'b1;
                        state <= ADDR;
                        bit_idx <= 4'h0;
                    end else if (scl_r && !scl_r2) begin // Rising edge of SCL
                        shift_reg <= {shift_reg[6:0], sda_r};
                        bit_idx <= bit_idx + 1'b1;
                        
                        if (bit_idx == 4'h7) begin
                            if (shift_reg[7:1] == self_addr) begin
                                state <= DATA;
                                bit_idx <= 4'h0;
                                // ACK
                                sda_oen <= 1'b0;
                                sda_out <= 1'b0;
                            end else begin
                                state <= IDLE;
                            end
                        end
                    end else if (!scl_r && scl_r2 && bit_idx == 4'h8) begin // ACK/NACK completed
                        sda_oen <= 1'b1; // Release SDA
                    end
                end
                
                DATA: begin
                    if (start_condition_buf2) begin
                        repeated_start_detected_reg <= 1'b1;
                        state <= ADDR;
                        bit_idx <= 4'h0;
                    end else if (stop_condition) begin
                        state <= IDLE;
                    end else if (scl_r && !scl_r2) begin // Rising edge of SCL
                        shift_reg <= {shift_reg[6:0], sda_r};
                        bit_idx <= bit_idx + 1'b1;
                        
                        if (bit_idx == 4'h7) begin
                            data_received_reg <= {shift_reg[6:0], sda_r};
                            state <= TRANSFER;
                            // ACK
                            sda_oen <= 1'b0;
                            sda_out <= 1'b0;
                        end
                    end else if (!scl_r && scl_r2 && bit_idx == 4'h8) begin // ACK/NACK completed
                        sda_oen <= 1'b1; // Release SDA
                        bit_idx <= 4'h0;
                    end
                end
                
                TRANSFER: begin
                    data_valid_reg <= 1'b1;
                    if (m_axis_tready) begin
                        data_valid_reg <= 1'b0;
                        state <= DATA;
                        bit_idx <= 4'h0;
                    end
                end
                
                default: state <= IDLE;
            endcase
            
            if (stop_condition) begin
                state <= IDLE;
            end
        end
    end
    
endmodule