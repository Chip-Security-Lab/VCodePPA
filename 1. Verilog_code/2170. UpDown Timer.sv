module updown_timer #(parameter WIDTH = 16)(
    input clk, rst_n, en, up_down,  // 1 = up, 0 = down
    input [WIDTH-1:0] load_val,
    input load_en,
    output reg [WIDTH-1:0] count,
    output wire overflow, underflow
);
    always @(posedge clk) begin
        if (!rst_n) count <= {WIDTH{1'b0}};
        else if (load_en) count <= load_val;
        else if (en) begin
            if (up_down) count <= count + 1'b1;
            else count <= count - 1'b1;
        end
    end
    assign overflow = en & up_down & (&count);
    assign underflow = en & ~up_down & (~|count);
endmodule