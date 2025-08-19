//SystemVerilog
module eth_mdio_interface (
    input wire clk,
    input wire reset,
    // Host interface
    input wire [4:0] phy_addr,
    input wire [4:0] reg_addr,
    input wire [15:0] write_data,
    output reg [15:0] read_data,
    input wire read_req,
    input wire write_req,
    output reg ready,
    output reg error,
    // MDIO interface
    output reg mdio_clk,
    inout wire mdio_data
);
    // State encoding - increased number of states for finer pipeline stages
    localparam IDLE = 4'd0, START_1 = 4'd1, START_2 = 4'd2, OP_1 = 4'd3, OP_2 = 4'd4;
    localparam PHY_ADDR_1 = 4'd5, PHY_ADDR_2 = 4'd6, REG_ADDR_1 = 4'd7, REG_ADDR_2 = 4'd8;
    localparam TA_1 = 4'd9, TA_2 = 4'd10, DATA_1 = 4'd11, DATA_2 = 4'd12, DATA_3 = 4'd13, DONE = 4'd14;
    
    reg [3:0] state, next_state;
    reg [5:0] bit_count, next_bit_count;
    reg [31:0] shift_reg_stage1, next_shift_reg_stage1;
    reg [31:0] shift_reg_stage2, next_shift_reg_stage2;
    reg mdio_out_stage1, next_mdio_out_stage1;
    reg mdio_out_stage2, next_mdio_out_stage2;
    reg mdio_oe_stage1, next_mdio_oe_stage1;
    reg mdio_oe_stage2, next_mdio_oe_stage2;
    reg next_ready, next_error;
    reg [15:0] read_data_stage1, next_read_data_stage1;
    reg [15:0] read_data_stage2, next_read_data_stage2;
    reg next_mdio_clk;
    
    // Control signals for pipeline stages
    reg req_valid_stage1, next_req_valid_stage1;
    reg req_valid_stage2, next_req_valid_stage2;
    reg req_type_stage1, next_req_type_stage1; // 0=read, 1=write
    reg req_type_stage2, next_req_type_stage2;
    
    // MDIO is a bidirectional signal
    assign mdio_data = mdio_oe_stage2 ? mdio_out_stage2 : 1'bz;
    
    // MDIO clock divider (host clock / 2)
    reg mdio_clk_div_stage1, next_mdio_clk_div_stage1;
    reg mdio_clk_div_stage2, next_mdio_clk_div_stage2;
    
    // Pipeline register update logic
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            bit_count <= 6'd0;
            mdio_clk <= 1'b1;
            mdio_out_stage1 <= 1'b1;
            mdio_out_stage2 <= 1'b1;
            mdio_oe_stage1 <= 1'b0;
            mdio_oe_stage2 <= 1'b0;
            ready <= 1'b1;
            error <= 1'b0;
            read_data <= 16'd0;
            read_data_stage1 <= 16'd0;
            read_data_stage2 <= 16'd0;
            mdio_clk_div_stage1 <= 1'b0;
            mdio_clk_div_stage2 <= 1'b0;
            shift_reg_stage1 <= 32'd0;
            shift_reg_stage2 <= 32'd0;
            req_valid_stage1 <= 1'b0;
            req_valid_stage2 <= 1'b0;
            req_type_stage1 <= 1'b0;
            req_type_stage2 <= 1'b0;
        end else begin
            state <= next_state;
            bit_count <= next_bit_count;
            mdio_clk <= next_mdio_clk;
            mdio_out_stage1 <= next_mdio_out_stage1;
            mdio_out_stage2 <= next_mdio_out_stage2;
            mdio_oe_stage1 <= next_mdio_oe_stage1;
            mdio_oe_stage2 <= next_mdio_oe_stage2;
            ready <= next_ready;
            error <= next_error;
            read_data <= next_read_data_stage2;
            read_data_stage1 <= next_read_data_stage1;
            read_data_stage2 <= next_read_data_stage2;
            mdio_clk_div_stage1 <= next_mdio_clk_div_stage1;
            mdio_clk_div_stage2 <= next_mdio_clk_div_stage2;
            shift_reg_stage1 <= next_shift_reg_stage1;
            shift_reg_stage2 <= next_shift_reg_stage2;
            req_valid_stage1 <= next_req_valid_stage1;
            req_valid_stage2 <= next_req_valid_stage2;
            req_type_stage1 <= next_req_type_stage1;
            req_type_stage2 <= next_req_type_stage2;
        end
    end
    
    // Clock divider logic - pipeline stage 1
    always @(*) begin
        next_mdio_clk_div_stage1 = ~mdio_clk_div_stage1;
        next_mdio_clk_div_stage2 = mdio_clk_div_stage1;
    end
    
    // First pipeline stage - request handling and shift register preparation
    always @(*) begin
        // Default: maintain current values
        next_req_valid_stage1 = req_valid_stage1;
        next_req_type_stage1 = req_type_stage1;
        next_shift_reg_stage1 = shift_reg_stage1;
        next_mdio_out_stage1 = mdio_out_stage1;
        next_mdio_oe_stage1 = mdio_oe_stage1;
        next_read_data_stage1 = read_data_stage1;
        
        // Request handling
        if (state == IDLE) begin
            if (read_req) begin
                // Format: <Preamble><ST><OP><PHYAD><REGAD><TA><DATA>
                next_shift_reg_stage1 = {32'hFFFFFFFF, 2'b01, 2'b10, phy_addr, reg_addr, 2'b00, 16'h0000};
                next_req_valid_stage1 = 1'b1;
                next_req_type_stage1 = 1'b0; // Read operation
                next_mdio_oe_stage1 = 1'b1;
            end else if (write_req) begin
                next_shift_reg_stage1 = {32'hFFFFFFFF, 2'b01, 2'b01, phy_addr, reg_addr, 2'b10, write_data};
                next_req_valid_stage1 = 1'b1;
                next_req_type_stage1 = 1'b1; // Write operation
                next_mdio_oe_stage1 = 1'b1;
            end else begin
                next_req_valid_stage1 = 1'b0;
                next_mdio_oe_stage1 = 1'b0;
            end
        end
        
        // Bit processing for first half of pipeline
        case (state)
            START_1, START_2: begin
                next_mdio_out_stage1 = 1'b1; // Preamble bits are all 1's
            end
            
            OP_1, OP_2: begin
                next_mdio_out_stage1 = shift_reg_stage1[31-bit_count];
            end
            
            PHY_ADDR_1, PHY_ADDR_2: begin
                next_mdio_out_stage1 = shift_reg_stage1[27-bit_count];
            end
            
            default: begin
                // Maintain current values
            end
        endcase
        
        // Read data processing
        if ((state == DATA_1 || state == DATA_2 || state == DATA_3) && !req_type_stage1 && mdio_clk == 1'b1) begin
            next_read_data_stage1[15-bit_count] = mdio_data;
        end
    end
    
    // Second pipeline stage - MDIO output generation
    always @(*) begin
        // Default: maintain current values
        next_req_valid_stage2 = req_valid_stage2;
        next_req_type_stage2 = req_type_stage2;
        next_shift_reg_stage2 = shift_reg_stage2;
        next_mdio_out_stage2 = mdio_out_stage2;
        next_mdio_oe_stage2 = mdio_oe_stage2;
        next_read_data_stage2 = read_data_stage2;
        
        // Pipeline forwarding
        if (state == IDLE) begin
            next_req_valid_stage2 = req_valid_stage1;
            next_req_type_stage2 = req_type_stage1;
            next_shift_reg_stage2 = shift_reg_stage1;
            next_mdio_oe_stage2 = mdio_oe_stage1;
        end
        
        // Bit processing for second half of pipeline
        case (state)
            REG_ADDR_1, REG_ADDR_2: begin
                next_mdio_out_stage2 = shift_reg_stage2[22-bit_count];
            end
            
            TA_1, TA_2: begin
                if (!req_type_stage2 && bit_count == 1)
                    next_mdio_oe_stage2 = 1'b0; // Release bus for READ operation
                else
                    next_mdio_out_stage2 = shift_reg_stage2[17-bit_count];
            end
            
            DATA_1, DATA_2, DATA_3: begin
                if (req_type_stage2) begin
                    // Write data operation
                    next_mdio_out_stage2 = shift_reg_stage2[15-bit_count];
                end
            end
            
            DONE: begin
                next_mdio_oe_stage2 = 1'b0;
                next_read_data_stage2 = read_data_stage1;
            end
            
            default: begin
                // Maintain current values
            end
        endcase
    end
    
    // State machine control with more pipeline stages
    always @(*) begin
        // Default values
        next_state = state;
        next_bit_count = bit_count;
        next_ready = ready;
        next_error = error;
        next_mdio_clk = mdio_clk;
        
        if (mdio_clk_div_stage2) begin // Only update on MDC clock edge
            case (state)
                IDLE: begin
                    next_mdio_clk = 1'b1;
                    
                    if (req_valid_stage2) begin
                        next_state = START_1;
                        next_bit_count = 6'd0;
                        next_ready = 1'b0;
                        next_error = 1'b0;
                    end
                end
                
                START_1: begin
                    next_mdio_clk = ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // On rising edge of MDC
                        if (bit_count == 15) begin
                            next_state = START_2;
                            next_bit_count = 6'd0;
                        end else begin
                            next_bit_count = bit_count + 1'b1;
                        end
                    end
                end
                
                START_2: begin
                    next_mdio_clk = ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // On rising edge of MDC
                        if (bit_count == 15) begin
                            next_state = OP_1;
                            next_bit_count = 6'd0;
                        end else begin
                            next_bit_count = bit_count + 1'b1;
                        end
                    end
                end
                
                OP_1: begin
                    next_mdio_clk = ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // On rising edge of MDC
                        if (bit_count == 1) begin
                            next_state = OP_2;
                            next_bit_count = 6'd0;
                        end else begin
                            next_bit_count = bit_count + 1'b1;
                        end
                    end
                end
                
                OP_2: begin
                    next_mdio_clk = ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // On rising edge of MDC
                        if (bit_count == 1) begin
                            next_state = PHY_ADDR_1;
                            next_bit_count = 6'd0;
                        end else begin
                            next_bit_count = bit_count + 1'b1;
                        end
                    end
                end
                
                PHY_ADDR_1: begin
                    next_mdio_clk = ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // On rising edge of MDC
                        if (bit_count == 2) begin
                            next_state = PHY_ADDR_2;
                            next_bit_count = 6'd0;
                        end else begin
                            next_bit_count = bit_count + 1'b1;
                        end
                    end
                end
                
                PHY_ADDR_2: begin
                    next_mdio_clk = ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // On rising edge of MDC
                        if (bit_count == 1) begin
                            next_state = REG_ADDR_1;
                            next_bit_count = 6'd0;
                        end else begin
                            next_bit_count = bit_count + 1'b1;
                        end
                    end
                end
                
                REG_ADDR_1: begin
                    next_mdio_clk = ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // On rising edge of MDC
                        if (bit_count == 2) begin
                            next_state = REG_ADDR_2;
                            next_bit_count = 6'd0;
                        end else begin
                            next_bit_count = bit_count + 1'b1;
                        end
                    end
                end
                
                REG_ADDR_2: begin
                    next_mdio_clk = ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // On rising edge of MDC
                        if (bit_count == 1) begin
                            next_state = TA_1;
                            next_bit_count = 6'd0;
                        end else begin
                            next_bit_count = bit_count + 1'b1;
                        end
                    end
                end
                
                TA_1: begin
                    next_mdio_clk = ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // On rising edge of MDC
                        next_state = TA_2;
                        next_bit_count = 6'd0;
                    end
                end
                
                TA_2: begin
                    next_mdio_clk = ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // On rising edge of MDC
                        next_state = DATA_1;
                        next_bit_count = 6'd0;
                    end
                end
                
                DATA_1: begin
                    next_mdio_clk = ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // On rising edge of MDC
                        if (bit_count == 5) begin
                            next_state = DATA_2;
                            next_bit_count = 6'd0;
                        end else begin
                            next_bit_count = bit_count + 1'b1;
                        end
                    end
                end
                
                DATA_2: begin
                    next_mdio_clk = ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // On rising edge of MDC
                        if (bit_count == 5) begin
                            next_state = DATA_3;
                            next_bit_count = 6'd0;
                        end else begin
                            next_bit_count = bit_count + 1'b1;
                        end
                    end
                end
                
                DATA_3: begin
                    next_mdio_clk = ~mdio_clk;
                    
                    if (mdio_clk == 1'b0) begin // On rising edge of MDC
                        if (bit_count == 3) begin
                            next_state = DONE;
                        end else begin
                            next_bit_count = bit_count + 1'b1;
                        end
                    end
                end
                
                DONE: begin
                    next_mdio_clk = 1'b1;
                    next_ready = 1'b1;
                    next_state = IDLE;
                end
                
                default: next_state = IDLE;
            endcase
        end
    end
endmodule