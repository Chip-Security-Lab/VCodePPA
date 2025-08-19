//SystemVerilog
module i2c_task_based #(
    parameter CMD_FIFO_DEPTH = 4
)(
    input  logic        clk,
    input  logic        rst_n,
    inout  wire         sda,
    inout  wire         scl,
    input  logic        cmd_valid,
    input  logic [15:0] cmd_word,
    output logic        cmd_ready
);
    // State definitions using one-hot encoding for optimal state machine implementation
    localparam [6:0] IDLE  = 7'b0000001;
    localparam [6:0] START = 7'b0000010;
    localparam [6:0] ADDR  = 7'b0000100;
    localparam [6:0] DATA  = 7'b0001000;
    localparam [6:0] ACK   = 7'b0010000;
    localparam [6:0] STOP  = 7'b0100000;
    localparam [6:0] WAIT  = 7'b1000000;
    
    // ===== STAGE 1: COMMAND DECODING AND STATE CONTROL =====
    // Command decoder stage - Preprocessed signals
    logic is_start_cmd;
    logic [7:0] addr_data, write_data;
    
    // State control registers
    logic [6:0] current_state, next_state;
    logic [2:0] bit_counter, next_bit_counter;
    logic       cmd_ready_next;
    
    // Command decoder - Extract control and data signals
    assign is_start_cmd = cmd_valid && (cmd_word[15:12] == 4'h1);
    assign addr_data = cmd_word[11:4];
    assign write_data = cmd_word[7:0];
    
    // ===== STAGE 2: DATA PATH PIPELINE =====
    // Data path pipeline registers
    logic [6:0] state_pipe;
    logic [2:0] bit_counter_pipe;
    logic [7:0] addr_buffer;
    logic [7:0] data_buffer;
    
    // ===== STAGE 3: CONTROL SIGNAL GENERATION =====
    // Control signal generation logic
    logic sda_out_next, scl_out_next;
    logic sda_oe_next, scl_oe_next;
    logic sda_out_reg, scl_out_reg;
    logic sda_oe_reg, scl_oe_reg;
    
    // ===== STAGE 4: OUTPUT DRIVE STAGE =====
    // Final output stage registers
    logic sda_out_final, scl_out_final;
    logic sda_oe_final, scl_oe_final;
    
    // I2C bus tri-state control
    assign sda = sda_oe_final ? sda_out_final : 1'bz;
    assign scl = scl_oe_final ? scl_out_final : 1'bz;
    
    //////////////////////////////////////////////////////////
    // STAGE 1: FSM State Control and Transition Logic
    //////////////////////////////////////////////////////////
    always_comb begin
        // Default values - maintain current state
        next_state = current_state;
        next_bit_counter = bit_counter;
        cmd_ready_next = cmd_ready;
        
        case (current_state)
            IDLE: begin
                if (is_start_cmd) begin
                    next_state = START;
                    cmd_ready_next = 1'b0;
                end else begin
                    cmd_ready_next = 1'b1;
                end
            end
            
            START: begin
                next_state = ADDR;
                next_bit_counter = 3'h0;
            end
            
            ADDR: begin
                if (scl_out_reg == 1'b0) begin
                    if (bit_counter == 3'h7) begin
                        next_bit_counter = 3'h0;
                        next_state = ACK;
                    end else begin
                        next_bit_counter = bit_counter + 1'b1;
                    end
                end
            end
            
            ACK: begin
                if (scl_out_reg == 1'b0) begin
                    next_state = DATA;
                end
            end
            
            DATA: begin
                if (scl_out_reg == 1'b0) begin
                    if (bit_counter == 3'h7) begin
                        next_bit_counter = 3'h0;
                        next_state = STOP;
                    end else begin
                        next_bit_counter = bit_counter + 1'b1;
                    end
                end
            end
            
            STOP: begin
                next_state = WAIT;
            end
            
            WAIT: begin
                next_state = IDLE;
                cmd_ready_next = 1'b1;
            end
            
            default: next_state = IDLE;
        endcase
    end
    
    //////////////////////////////////////////////////////////
    // STAGE 2: I2C Signal Generation Logic
    //////////////////////////////////////////////////////////
    always_comb begin
        // Default - maintain current values
        sda_out_next = sda_out_reg;
        scl_out_next = scl_out_reg;
        sda_oe_next = sda_oe_reg;
        scl_oe_next = scl_oe_reg;
        
        case (state_pipe)
            IDLE: begin
                // Bus idle state - high impedance
                sda_out_next = 1'b1;
                scl_out_next = 1'b1;
                sda_oe_next = 1'b0;
                scl_oe_next = 1'b0;
            end
            
            START: begin
                // START condition - SDA falls while SCL high
                sda_oe_next = 1'b1;
                scl_oe_next = 1'b1;
                scl_out_next = 1'b1;
                sda_out_next = 1'b0;
            end
            
            ADDR: begin
                // Address transmission - toggle SCL and drive SDA with address bits
                sda_oe_next = 1'b1;
                scl_oe_next = 1'b1;
                scl_out_next = !scl_out_reg; // Toggle clock
                
                if (scl_out_reg == 1'b0) begin
                    // Update SDA on SCL low
                    sda_out_next = addr_buffer[7 - bit_counter_pipe];
                end
            end
            
            ACK: begin
                // ACK bit - release SDA and toggle SCL
                scl_oe_next = 1'b1;
                scl_out_next = !scl_out_reg; // Toggle clock
                
                if (scl_out_reg == 1'b0) begin
                    sda_oe_next = 1'b0; // Release SDA to let slave drive ACK
                end
            end
            
            DATA: begin
                // Data transmission - toggle SCL and drive SDA with data bits
                sda_oe_next = 1'b1;
                scl_oe_next = 1'b1;
                scl_out_next = !scl_out_reg; // Toggle clock
                
                if (scl_out_reg == 1'b0) begin
                    // Update SDA on SCL low
                    sda_out_next = data_buffer[7 - bit_counter_pipe];
                end
            end
            
            STOP: begin
                // STOP condition - SDA rises while SCL high
                sda_oe_next = 1'b1;
                scl_oe_next = 1'b1;
                scl_out_next = 1'b1;
                sda_out_next = 1'b0; // SDA low first, then rises in WAIT
            end
            
            WAIT: begin
                // Complete STOP condition - SDA rises while SCL high
                sda_out_next = 1'b1;
                sda_oe_next = 1'b1;
                scl_oe_next = 1'b1;
                scl_out_next = 1'b1;
            end
            
            default: begin
                // Safe default - release bus
                sda_out_next = 1'b1;
                scl_out_next = 1'b1;
                sda_oe_next = 1'b0;
                scl_oe_next = 1'b0;
            end
        endcase
    end
    
    //////////////////////////////////////////////////////////
    // Sequential Logic for Pipeline Stages
    //////////////////////////////////////////////////////////
    
    // Stage 1: State Control Pipeline
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= IDLE;
            bit_counter <= 3'h0;
            cmd_ready <= 1'b1;
        end else begin
            current_state <= next_state;
            bit_counter <= next_bit_counter;
            cmd_ready <= cmd_ready_next;
        end
    end
    
    // Stage 2: Data Path Pipeline
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_pipe <= IDLE;
            bit_counter_pipe <= 3'h0;
            addr_buffer <= 8'h0;
            data_buffer <= 8'h0;
        end else begin
            state_pipe <= current_state;
            bit_counter_pipe <= bit_counter;
            
            // Load data on command receive
            if (current_state == IDLE && is_start_cmd) begin
                addr_buffer <= addr_data;
                data_buffer <= write_data;
            end
        end
    end
    
    // Stage 3: Control Signal Pipeline
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_out_reg <= 1'b1;
            scl_out_reg <= 1'b1;
            sda_oe_reg <= 1'b0;
            scl_oe_reg <= 1'b0;
        end else begin
            sda_out_reg <= sda_out_next;
            scl_out_reg <= scl_out_next;
            sda_oe_reg <= sda_oe_next;
            scl_oe_reg <= scl_oe_next;
        end
    end
    
    // Stage 4: Output Drive Pipeline - last stage before physical I/O
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sda_out_final <= 1'b1;
            scl_out_final <= 1'b1;
            sda_oe_final <= 1'b0;
            scl_oe_final <= 1'b0;
        end else begin
            sda_out_final <= sda_out_reg;
            scl_out_final <= scl_out_reg;
            sda_oe_final <= sda_oe_reg;
            scl_oe_final <= scl_oe_reg;
        end
    end
    
endmodule