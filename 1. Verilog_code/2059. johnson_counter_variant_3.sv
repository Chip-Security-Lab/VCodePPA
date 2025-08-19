//SystemVerilog
module johnson_counter #(parameter WIDTH = 4) (
    input wire clk,
    input wire rst_n,
    input wire enable,
    output wire [WIDTH-1:0] johnson_code
);

    // State encoding
    localparam [1:0] RESET_STATE  = 2'b00;
    localparam [1:0] ENABLE_STATE = 2'b01;
    localparam [1:0] HOLD_STATE   = 2'b10;

    reg [1:0] ctrl_state_reg;
    reg [1:0] ctrl_state_buf;
    reg [WIDTH-1:0] johnson_code_reg;
    reg [WIDTH-1:0] johnson_code_buf;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ctrl_state_reg    <= RESET_STATE;
            ctrl_state_buf    <= RESET_STATE;
            johnson_code_reg  <= {WIDTH{1'b0}};
            johnson_code_buf  <= {WIDTH{1'b0}};
        end else begin
            // ctrl_state_reg logic
            if (enable)
                ctrl_state_reg <= ENABLE_STATE;
            else
                ctrl_state_reg <= HOLD_STATE;

            // ctrl_state_buf logic
            ctrl_state_buf <= ctrl_state_reg;

            // johnson_code_reg logic
            case (ctrl_state_buf)
                RESET_STATE:  johnson_code_reg <= {WIDTH{1'b0}};
                ENABLE_STATE: johnson_code_reg <= {~johnson_code_reg[0], johnson_code_reg[WIDTH-1:1]};
                HOLD_STATE:   johnson_code_reg <= johnson_code_reg;
                default:      johnson_code_reg <= johnson_code_reg;
            endcase

            // johnson_code_buf logic
            johnson_code_buf <= johnson_code_reg;
        end
    end

    assign johnson_code = johnson_code_buf;

endmodule