//SystemVerilog
module i2c_codec (
    input wire clk, rstn, 
    input wire start_xfer, rw,
    input wire [6:0] addr,
    input wire [7:0] wr_data,
    inout wire sda,
    output reg scl,
    output reg [7:0] rd_data,
    output reg busy, done
);
    // State definitions
    localparam IDLE=0, START=1, ADDR=2, RW=3, ACK1=4, DATA=5, ACK2=6, STOP=7;
    
    // Main control registers
    reg [2:0] state, next_state;
    reg [3:0] bit_cnt, next_bit_cnt;
    reg [7:0] shift_reg, next_shift_reg;
    reg sda_out, next_sda_out;
    reg sda_oe, next_sda_oe;
    reg next_scl;
    reg next_busy, next_done;
    
    // Enhanced pipeline registers (4-stage pipeline)
    reg [7:0] stage1_shift_reg, stage2_shift_reg, stage3_shift_reg;
    reg [2:0] stage1_state, stage2_state, stage3_state;
    reg [3:0] stage1_bit_cnt, stage2_bit_cnt, stage3_bit_cnt;
    reg stage1_sda_out, stage2_sda_out, stage3_sda_out;
    reg stage1_sda_oe, stage2_sda_oe, stage3_sda_oe;
    reg stage1_scl, stage2_scl, stage3_scl;
    reg stage1_busy, stage2_busy, stage3_busy;
    reg stage1_done, stage2_done, stage3_done;
    
    // Intermediate combinational logic results
    reg comp_rw_valid, comp_addr_valid, comp_data_valid;
    reg [1:0] comp_phase_counter;
    
    // SDA tristate control
    assign sda = sda_oe ? sda_out : 1'bz;
    
    // Sequential logic with enhanced pipeline stages
    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin 
            // Initialize all pipeline registers
            state <= IDLE;
            bit_cnt <= 0;
            scl <= 1'b1;
            shift_reg <= 8'h00;
            sda_out <= 1'b1;
            sda_oe <= 1'b1;
            busy <= 1'b0;
            done <= 1'b0;
            
            // Stage 1 pipeline registers
            stage1_state <= IDLE;
            stage1_bit_cnt <= 0;
            stage1_shift_reg <= 8'h00;
            stage1_sda_out <= 1'b1;
            stage1_sda_oe <= 1'b1;
            stage1_scl <= 1'b1;
            stage1_busy <= 1'b0;
            stage1_done <= 1'b0;
            
            // Stage 2 pipeline registers
            stage2_state <= IDLE;
            stage2_bit_cnt <= 0;
            stage2_shift_reg <= 8'h00;
            stage2_sda_out <= 1'b1;
            stage2_sda_oe <= 1'b1;
            stage2_scl <= 1'b1;
            stage2_busy <= 1'b0;
            stage2_done <= 1'b0;
            
            // Stage 3 pipeline registers
            stage3_state <= IDLE;
            stage3_bit_cnt <= 0;
            stage3_shift_reg <= 8'h00;
            stage3_sda_out <= 1'b1;
            stage3_sda_oe <= 1'b1;
            stage3_scl <= 1'b1;
            stage3_busy <= 1'b0;
            stage3_done <= 1'b0;
        end 
        else begin
            // Pipeline stage 1: Capture next state values
            stage1_state <= next_state;
            stage1_bit_cnt <= next_bit_cnt;
            stage1_shift_reg <= next_shift_reg;
            stage1_sda_out <= next_sda_out;
            stage1_sda_oe <= next_sda_oe;
            stage1_scl <= next_scl;
            stage1_busy <= next_busy;
            stage1_done <= next_done;
            
            // Pipeline stage 2: Transition between stages
            stage2_state <= stage1_state;
            stage2_bit_cnt <= stage1_bit_cnt;
            stage2_shift_reg <= stage1_shift_reg;
            stage2_sda_out <= stage1_sda_out;
            stage2_sda_oe <= stage1_sda_oe;
            stage2_scl <= stage1_scl;
            stage2_busy <= stage1_busy;
            stage2_done <= stage1_done;
            
            // Pipeline stage 3: Final processing before output
            stage3_state <= stage2_state;
            stage3_bit_cnt <= stage2_bit_cnt;
            stage3_shift_reg <= stage2_shift_reg;
            stage3_sda_out <= stage2_sda_out;
            stage3_sda_oe <= stage2_sda_oe;
            stage3_scl <= stage2_scl;
            stage3_busy <= stage2_busy;
            stage3_done <= stage2_done;
            
            // Final stage (actual outputs)
            state <= stage3_state;
            bit_cnt <= stage3_bit_cnt;
            shift_reg <= stage3_shift_reg;
            sda_out <= stage3_sda_out;
            sda_oe <= stage3_sda_oe;
            scl <= stage3_scl;
            busy <= stage3_busy;
            done <= stage3_done;
            
            // Read data is updated with proper pipelining
            if (stage2_state == DATA && rw == 1'b1 && stage2_bit_cnt == 0)
                rd_data <= stage2_shift_reg;
        end
    end
    
    // Pre-compute some common conditions to reduce path delay
    always @(*) begin
        comp_rw_valid = (state == RW && scl == 1'b1);
        comp_addr_valid = (state == ADDR && scl == 1'b0 && bit_cnt == 4'h6);
        comp_data_valid = (state == DATA && scl == 1'b0 && bit_cnt == 4'h7);
        comp_phase_counter = {scl, sda_out}; // Used for STOP condition timing
    end
    
    // Combinational logic for next state and control signals - split into smaller blocks
    always @(*) begin
        // Default assignments to avoid latches
        next_state = state;
        next_bit_cnt = bit_cnt;
        next_shift_reg = shift_reg;
        next_sda_out = sda_out;
        next_sda_oe = sda_oe;
        next_scl = scl;
        next_busy = busy;
        next_done = done;
        
        case (state)
            IDLE: begin
                next_scl = 1'b1;
                next_sda_out = 1'b1;
                next_sda_oe = 1'b1;
                next_bit_cnt = 4'h0;
                next_busy = 1'b0;
                next_done = 1'b0;
                
                if (start_xfer) begin
                    next_state = START;
                    next_busy = 1'b1;
                    next_shift_reg = {addr, 1'b0}; // Prepare addr+rw bit
                end
            end
            
            START: begin
                next_sda_out = 1'b0;
                next_scl = 1'b0;
                next_state = ADDR;
            end
            
            ADDR: begin
                next_sda_out = shift_reg[7];
                next_scl = ~scl; // Toggle SCL
                
                if (scl == 1'b0) begin // On rising edge
                    if (bit_cnt == 4'h6) begin
                        next_bit_cnt = 4'h0;
                        next_state = RW;
                    end
                    else begin
                        next_bit_cnt = bit_cnt + 4'h1;
                    end
                end
                
                if (scl == 1'b1) begin // On falling edge
                    next_shift_reg = {shift_reg[6:0], 1'b0}; // Shift left
                end
            end
            
            RW: begin
                next_sda_out = rw;
                next_scl = ~scl;
                
                if (scl == 1'b1) begin // On falling edge
                    next_state = ACK1;
                    next_sda_oe = 1'b0; // Release SDA for slave ACK
                end
            end
            
            ACK1: begin
                next_scl = ~scl;
                
                if (scl == 1'b0) begin // On rising edge
                    // Check for ACK (SDA should be low)
                    if (sda == 1'b0) begin
                        next_state = DATA;
                        next_sda_oe = 1'b1; // Take control of SDA again
                        
                        if (rw == 1'b0) begin // Write operation
                            next_shift_reg = wr_data;
                        end
                        else begin // Read operation
                            next_shift_reg = 8'h00; // Clear for receiving
                        end
                    end
                    else begin
                        next_state = STOP; // No ACK, go to stop
                    end
                end
            end
            
            DATA: begin
                if (rw == 1'b0) begin // Write data
                    next_sda_oe = 1'b1;
                    next_sda_out = shift_reg[7];
                end
                else begin // Read data
                    next_sda_oe = 1'b0; // Release SDA for slave
                end
                
                next_scl = ~scl;
                
                if (scl == 1'b0) begin // On rising edge
                    if (bit_cnt == 4'h7) begin
                        next_bit_cnt = 4'h0;
                        next_state = ACK2;
                    end
                    else begin
                        next_bit_cnt = bit_cnt + 4'h1;
                    end
                    
                    if (rw == 1'b1) begin // Read operation, sample data
                        next_shift_reg = {shift_reg[6:0], sda};
                    end
                end
                
                if (scl == 1'b1 && rw == 1'b0) begin // On falling edge during write
                    next_shift_reg = {shift_reg[6:0], 1'b0}; // Shift left
                end
            end
            
            ACK2: begin
                next_scl = ~scl;
                
                if (rw == 1'b0) begin // Write operation
                    next_sda_oe = 1'b0; // Release SDA for slave ACK
                end
                else begin // Read operation
                    next_sda_oe = 1'b1;
                    next_sda_out = 1'b1; // NACK to indicate end of read
                end
                
                if (scl == 1'b0) begin // On rising edge
                    next_state = STOP;
                    next_sda_oe = 1'b1; // Take control for STOP
                    next_sda_out = 1'b0; // Prepare for STOP (SDA low)
                end
            end
            
            STOP: begin
                next_sda_oe = 1'b1;
                
                if (scl == 1'b0) begin
                    next_scl = 1'b1; // SCL high
                end
                else if (scl == 1'b1 && sda_out == 1'b0) begin
                    next_sda_out = 1'b1; // SDA rising while SCL high = STOP
                    next_done = 1'b1;
                end
                else begin
                    next_state = IDLE;
                    next_busy = 1'b0;
                end
            end
            
            default: next_state = IDLE;
        endcase
    end
endmodule