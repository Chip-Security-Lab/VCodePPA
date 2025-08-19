//SystemVerilog
module mdio_codec (
    input wire clk, rst_n,
    input wire mdio_in, start_op,
    input wire read_mode,
    input wire [4:0] phy_addr,
    input wire [4:0] reg_addr, 
    input wire [15:0] wr_data,
    output reg mdio_out, mdio_oe,
    output reg [15:0] rd_data,
    output reg busy, data_valid
);
    
    localparam IDLE=0, START=1, OP=2, PHY_ADDR=3, REG_ADDR=4, TA=5, DATA=6;
    
    // Pipeline stage registers
    reg [2:0] state_stage1, state_stage2, next_state_stage1;
    reg [5:0] bit_count_stage1, bit_count_stage2, next_bit_count_stage1;
    reg [31:0] shift_reg_stage1, shift_reg_stage2, next_shift_reg_stage1;
    
    // Pipeline control signals
    reg valid_stage1, valid_stage2;
    reg [1:0] op_type_stage1, op_type_stage2; // 00: none, 01: write, 10: read
    
    // Input registration stage (Stage 0)
    reg start_op_r, read_mode_r;
    reg [4:0] phy_addr_r, reg_addr_r;
    reg [15:0] wr_data_r;
    
    // Pre-compute values (Stage 0)
    reg [31:0] shift_reg_data;
    
    // Input registration pipeline stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_op_r <= 1'b0;
            read_mode_r <= 1'b0;
            phy_addr_r <= 5'h0;
            reg_addr_r <= 5'h0;
            wr_data_r <= 16'h0;
            valid_stage1 <= 1'b0;
            op_type_stage1 <= 2'b00;
        end else begin
            start_op_r <= start_op;
            read_mode_r <= read_mode;
            phy_addr_r <= phy_addr;
            reg_addr_r <= reg_addr;
            wr_data_r <= wr_data;
            
            // Set valid signal for stage 1
            valid_stage1 <= start_op;
            op_type_stage1 <= start_op ? (read_mode ? 2'b10 : 2'b01) : 2'b00;
        end
    end
    
    // Stage 1: FSM computation and shift register preparation
    always @(*) begin
        next_state_stage1 = state_stage1;
        next_bit_count_stage1 = bit_count_stage1;
        next_shift_reg_stage1 = shift_reg_stage1;
        
        // Pre-compute the shift register data
        shift_reg_data = {2'b01, read_mode_r ? 2'b10 : 2'b01, phy_addr_r, reg_addr_r, 
                         read_mode_r ? 16'h0 : wr_data_r};
        
        case (state_stage1)
            IDLE: begin
                if (valid_stage1) begin
                    next_state_stage1 = START;
                    next_bit_count_stage1 = 0;
                    next_shift_reg_stage1 = shift_reg_data;
                end
            end
            START: begin
                next_bit_count_stage1 = bit_count_stage1 + 1;
                if (bit_count_stage1 == 1) begin
                    next_state_stage1 = OP;
                    next_bit_count_stage1 = 0;
                end
            end
            OP: begin
                next_bit_count_stage1 = bit_count_stage1 + 1;
                next_shift_reg_stage1 = {shift_reg_stage1[30:0], 1'b0};
                if (bit_count_stage1 == 1) begin
                    next_state_stage1 = PHY_ADDR;
                    next_bit_count_stage1 = 0;
                end
            end
            PHY_ADDR: begin
                next_bit_count_stage1 = bit_count_stage1 + 1;
                next_shift_reg_stage1 = {shift_reg_stage1[30:0], 1'b0};
                if (bit_count_stage1 == 4) begin
                    next_state_stage1 = REG_ADDR;
                    next_bit_count_stage1 = 0;
                end
            end
            REG_ADDR: begin
                next_bit_count_stage1 = bit_count_stage1 + 1;
                next_shift_reg_stage1 = {shift_reg_stage1[30:0], 1'b0};
                if (bit_count_stage1 == 4) begin
                    next_state_stage1 = TA;
                    next_bit_count_stage1 = 0;
                end
            end
            TA: begin
                next_bit_count_stage1 = bit_count_stage1 + 1;
                if (op_type_stage1 == 2'b01) begin // Write
                    next_shift_reg_stage1 = {shift_reg_stage1[30:0], 1'b0};
                end
                if (bit_count_stage1 == 1) begin
                    next_state_stage1 = DATA;
                    next_bit_count_stage1 = 0;
                end
            end
            DATA: begin
                next_bit_count_stage1 = bit_count_stage1 + 1;
                if (op_type_stage1 == 2'b01) begin // Write
                    next_shift_reg_stage1 = {shift_reg_stage1[30:0], 1'b0};
                end else begin // Read
                    next_shift_reg_stage1 = {shift_reg_stage1[30:0], mdio_in};
                end
                if (bit_count_stage1 == 15) begin
                    next_state_stage1 = IDLE;
                end
            end
            default: next_state_stage1 = IDLE;
        endcase
    end
    
    // Pipeline stage 1 sequential logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_stage1 <= IDLE;
            bit_count_stage1 <= 6'h0;
            shift_reg_stage1 <= 32'h0;
            valid_stage2 <= 1'b0;
            op_type_stage2 <= 2'b00;
        end else begin
            state_stage1 <= next_state_stage1;
            bit_count_stage1 <= next_bit_count_stage1;
            shift_reg_stage1 <= next_shift_reg_stage1;
            
            // Pass control signals to stage 2
            valid_stage2 <= valid_stage1;
            op_type_stage2 <= op_type_stage1;
            
            // Pass data to stage 2
            state_stage2 <= state_stage1;
            bit_count_stage2 <= bit_count_stage1;
            shift_reg_stage2 <= shift_reg_stage1;
        end
    end
    
    // Stage 2: Output generation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mdio_out <= 1'b1;
            mdio_oe <= 1'b0; 
            busy <= 1'b0;
            data_valid <= 1'b0;
            rd_data <= 16'h0;
        end else begin
            case (state_stage2)
                IDLE: begin
                    mdio_out <= 1'b1;
                    if (valid_stage2) begin
                        busy <= 1'b1;
                        mdio_oe <= 1'b1;
                        data_valid <= 1'b0;
                    end else begin
                        busy <= 1'b0;
                        mdio_oe <= 1'b0;
                    end
                end
                START: begin
                    mdio_oe <= 1'b1;
                    busy <= 1'b1;
                    mdio_out <= (bit_count_stage2 == 0) ? 1'b0 : 1'b1; // Start with '01'
                    data_valid <= 1'b0;
                end
                OP: begin
                    mdio_oe <= 1'b1;
                    busy <= 1'b1;
                    mdio_out <= shift_reg_stage2[31];
                    data_valid <= 1'b0;
                end
                PHY_ADDR: begin
                    mdio_oe <= 1'b1;
                    busy <= 1'b1;
                    mdio_out <= shift_reg_stage2[31];
                    data_valid <= 1'b0;
                end
                REG_ADDR: begin
                    mdio_oe <= 1'b1;
                    busy <= 1'b1;
                    mdio_out <= shift_reg_stage2[31];
                    data_valid <= 1'b0;
                end
                TA: begin
                    busy <= 1'b1;
                    data_valid <= 1'b0;
                    if (op_type_stage2 == 2'b01) begin // Write
                        mdio_oe <= 1'b1;
                        mdio_out <= (bit_count_stage2 == 0) ? 1'b1 : 1'b0; // TA is '10' for write
                    end else begin // Read
                        if (bit_count_stage2 == 0) begin
                            mdio_oe <= 1'b1;
                            mdio_out <= 1'b1; // First bit of TA is '1'
                        end else begin
                            mdio_oe <= 1'b0; // Release the bus for second bit
                            mdio_out <= 1'b1;
                        end
                    end
                end
                DATA: begin
                    busy <= 1'b1;
                    if (op_type_stage2 == 2'b01) begin // Write
                        mdio_oe <= 1'b1;
                        mdio_out <= shift_reg_stage2[31];
                        if (bit_count_stage2 == 15) begin
                            data_valid <= 1'b1; // Write complete
                        end
                    end else begin // Read
                        mdio_oe <= 1'b0;
                        if (bit_count_stage2 == 15) begin
                            data_valid <= 1'b1;
                            rd_data <= {shift_reg_stage2[14:0], mdio_in}; // Capture read data
                        end
                    end
                end
            endcase
        end
    end
endmodule