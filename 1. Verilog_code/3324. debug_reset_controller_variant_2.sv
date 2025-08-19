//SystemVerilog
module debug_reset_controller(
    input  wire        clk,
    input  wire        ext_rst_n,
    input  wire        dbg_enable,
    input  wire        dbg_halt,
    input  wire        dbg_step,
    input  wire        dbg_reset,
    output reg         cpu_rst_n,
    output reg         periph_rst_n,
    output reg [1:0]   debug_state
);

    // State encoding
    localparam NORMAL    = 2'b00;
    localparam HALTED    = 2'b01;
    localparam STEPPING  = 2'b10;
    localparam DBG_RESET = 2'b11;

    reg [1:0] current_state = NORMAL;
    reg [1:0] next_state;

    //-----------------------------------------------------------------------------
    // State Transition Logic
    //-----------------------------------------------------------------------------
    always @(*) begin
        case (current_state)
            NORMAL: begin
                if (dbg_enable && dbg_halt)
                    next_state = HALTED;
                else if (dbg_enable && dbg_reset)
                    next_state = DBG_RESET;
                else
                    next_state = NORMAL;
            end
            HALTED: begin
                if (!dbg_enable)
                    next_state = NORMAL;
                else if (dbg_step)
                    next_state = STEPPING;
                else if (dbg_reset)
                    next_state = DBG_RESET;
                else
                    next_state = HALTED;
            end
            STEPPING: begin
                next_state = HALTED;
            end
            DBG_RESET: begin
                next_state = HALTED;
            end
            default: begin
                next_state = NORMAL;
            end
        endcase
    end

    //-----------------------------------------------------------------------------
    // State Register
    //-----------------------------------------------------------------------------
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n)
            current_state <= NORMAL;
        else
            current_state <= next_state;
    end

    //-----------------------------------------------------------------------------
    // Output: Reset Control Logic
    //-----------------------------------------------------------------------------
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n) begin
            cpu_rst_n    <= 1'b0;
            periph_rst_n <= 1'b0;
        end else begin
            case (next_state)
                NORMAL: begin
                    cpu_rst_n    <= 1'b1;
                    periph_rst_n <= 1'b1;
                end
                HALTED: begin
                    cpu_rst_n    <= 1'b0;
                    periph_rst_n <= 1'b1;
                end
                STEPPING: begin
                    cpu_rst_n    <= 1'b1;
                    periph_rst_n <= 1'b1;
                end
                DBG_RESET: begin
                    cpu_rst_n    <= 1'b0;
                    periph_rst_n <= 1'b0;
                end
                default: begin
                    cpu_rst_n    <= 1'b0;
                    periph_rst_n <= 1'b0;
                end
            endcase
        end
    end

    //-----------------------------------------------------------------------------
    // Output: Debug State Register
    //-----------------------------------------------------------------------------
    always @(posedge clk or negedge ext_rst_n) begin
        if (!ext_rst_n)
            debug_state <= NORMAL;
        else
            debug_state <= current_state;
    end

endmodule