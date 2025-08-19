//SystemVerilog
module binary_gray_counter #(
    parameter WIDTH = 8,
    parameter MAX_COUNT = {WIDTH{1'b1}}
) (
    input  wire                 clock_in,
    input  wire                 reset_n,
    input  wire                 enable_in,
    input  wire                 up_down_n,  // 1=up, 0=down
    output reg  [WIDTH-1:0]     binary_count,
    output wire [WIDTH-1:0]     gray_count,
    output wire                 terminal_count
);
    // Convert binary to Gray code
    assign gray_count = binary_count ^ {1'b0, binary_count[WIDTH-1:1]};
    
    // Terminal count detection
    assign terminal_count = up_down_n ? (binary_count == MAX_COUNT) : 
                                        (binary_count == {WIDTH{1'b0}});
    
    // Binary counter logic
    always @(posedge clock_in or negedge reset_n) begin
        if (!reset_n)
            binary_count <= {WIDTH{1'b0}};
        else if (enable_in) begin
            case ({up_down_n, binary_count == MAX_COUNT, binary_count == {WIDTH{1'b0}}})
                3'b100: binary_count <= {WIDTH{1'b0}};  // Up counter at max
                3'b101: binary_count <= binary_count + 1'b1;  // Up counter not at max
                3'b010: binary_count <= MAX_COUNT;  // Down counter at zero
                3'b011: binary_count <= binary_count - 1'b1;  // Down counter not at zero
                default: binary_count <= binary_count;  // Hold current value
            endcase
        end
    end
endmodule