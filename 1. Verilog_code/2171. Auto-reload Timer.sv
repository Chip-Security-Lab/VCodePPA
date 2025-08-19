module auto_reload_timer (
    input wire clk, rstn, en, reload_en,
    input wire [31:0] reload_val,
    output reg [31:0] count,
    output reg timeout
);
    reg [31:0] reload_reg;
    always @(posedge clk) begin
        if (!rstn) reload_reg <= 32'hFFFFFFFF;
        else if (reload_en) reload_reg <= reload_val;
    end
    always @(posedge clk) begin
        if (!rstn) begin count <= 32'h0; timeout <= 1'b0; end
        else if (en) begin
            if (count == reload_reg) begin
                count <= 32'h0; timeout <= 1'b1;
            end else begin count <= count + 32'h1; timeout <= 1'b0; end
        end
    end
endmodule