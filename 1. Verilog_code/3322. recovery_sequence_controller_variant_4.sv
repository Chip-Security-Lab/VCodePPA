//SystemVerilog
module recovery_sequence_controller(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        trigger_recovery,
    output reg  [3:0]  recovery_stage,
    output reg         recovery_in_progress,
    output reg         system_reset,
    output reg         module_reset,
    output reg         memory_clear
);

    // State encoding
    localparam IDLE        = 3'd0,
               RESET       = 3'd1,
               MODULE_RST  = 3'd2,
               MEM_CLEAR   = 3'd3,
               WAIT        = 3'd4;

    reg [2:0] current_state, next_state;
    reg [7:0] counter, next_counter;

    // Thresholds for each state for efficient comparison
    localparam [7:0] RESET_THR      = 8'hFF,
                     MODULE_RST_THR = 8'h7F,
                     MEM_CLEAR_THR  = 8'h3F,
                     WAIT_THR       = 8'hFF;

    //===============================================================
    // State Register: Handles state transitions
    //===============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            current_state <= IDLE;
        else
            current_state <= next_state;
    end

    //===============================================================
    // Counter Register: Handles counter value for each state
    //===============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            counter <= 8'h00;
        else
            counter <= next_counter;
    end

    //===============================================================
    // Next State & Next Counter Logic (Optimized Comparison)
    //===============================================================
    always @(*) begin
        // Default assignments
        next_state   = current_state;
        next_counter = counter;

        case (current_state)
            IDLE: begin
                if (trigger_recovery) begin
                    next_state   = RESET;
                    next_counter = 8'h00;
                end
            end
            RESET: begin
                if (counter >= RESET_THR) begin
                    next_state   = MODULE_RST;
                    next_counter = 8'h00;
                end else begin
                    next_counter = counter + 1'b1;
                end
            end
            MODULE_RST: begin
                if (counter >= MODULE_RST_THR) begin
                    next_state   = MEM_CLEAR;
                    next_counter = 8'h00;
                end else begin
                    next_counter = counter + 1'b1;
                end
            end
            MEM_CLEAR: begin
                if (counter >= MEM_CLEAR_THR) begin
                    next_state   = WAIT;
                    next_counter = 8'h00;
                end else begin
                    next_counter = counter + 1'b1;
                end
            end
            WAIT: begin
                if (counter >= WAIT_THR) begin
                    next_state   = IDLE;
                    next_counter = 8'h00;
                end else begin
                    next_counter = counter + 1'b1;
                end
            end
            default: begin
                next_state   = IDLE;
                next_counter = 8'h00;
            end
        endcase
    end

    //===============================================================
    // Recovery Stage Register: Indicates recovery step
    //===============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            recovery_stage <= 4'h0;
        else begin
            case (next_state)
                IDLE:       recovery_stage <= 4'h0;
                RESET:      recovery_stage <= 4'h1;
                MODULE_RST: recovery_stage <= 4'h2;
                MEM_CLEAR:  recovery_stage <= 4'h3;
                WAIT:       recovery_stage <= 4'h4;
                default:    recovery_stage <= 4'h0;
            endcase
        end
    end

    //===============================================================
    // Recovery In Progress Register (Optimized Comparison)
    //===============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            recovery_in_progress <= 1'b0;
        else begin
            if ((current_state == IDLE) && trigger_recovery)
                recovery_in_progress <= 1'b1;
            else if ((current_state == WAIT) && (counter >= WAIT_THR))
                recovery_in_progress <= 1'b0;
        end
    end

    //===============================================================
    // System Reset Signal Generation (Optimized Comparison)
    //===============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            system_reset <= 1'b0;
        else if (current_state == RESET)
            system_reset <= 1'b1;
        else if (next_state != RESET)
            system_reset <= 1'b0;
    end

    //===============================================================
    // Module Reset Signal Generation (Optimized Comparison)
    //===============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            module_reset <= 1'b0;
        else if (current_state == MODULE_RST)
            module_reset <= 1'b1;
        else if (next_state != MODULE_RST)
            module_reset <= 1'b0;
    end

    //===============================================================
    // Memory Clear Signal Generation (Optimized Comparison)
    //===============================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            memory_clear <= 1'b0;
        else if (current_state == MEM_CLEAR)
            memory_clear <= 1'b1;
        else if (next_state != MEM_CLEAR)
            memory_clear <= 1'b0;
    end

endmodule