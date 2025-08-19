//SystemVerilog
module johnson_counter #(parameter WIDTH = 4) (
    input wire clk,
    input wire rst_n,
    input wire enable,
    output reg [WIDTH-1:0] johnson_code
);

    localparam [1:0] RESET  = 2'b00;
    localparam [1:0] UPDATE = 2'b01;
    localparam [1:0] HOLD   = 2'b10;

    reg [1:0] next_state;

    always @(*) begin
        case ({~rst_n, enable})
            2'b10: next_state = RESET;
            2'b01: next_state = UPDATE;
            default: next_state = HOLD;
        endcase
    end

    wire [WIDTH-1:0] next_johnson_code;
    assign next_johnson_code = {~johnson_code[0], johnson_code[WIDTH-1:1]};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            johnson_code <= {WIDTH{1'b0}};
        end else begin
            if (next_state == RESET)
                johnson_code <= {WIDTH{1'b0}};
            else if (next_state == UPDATE)
                johnson_code <= next_johnson_code;
            // No need for HOLD/default, as johnson_code retains its value if not assigned
        end
    end

endmodule