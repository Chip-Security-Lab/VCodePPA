module task_based(
    input wire clk,
    input wire rst_n,
    input wire [3:0] in,
    output reg [1:0] out
);

    // Pipeline stage 1: Input register
    reg [3:0] in_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_reg <= 4'b0;
        end else begin
            in_reg <= in;
        end
    end

    // Pipeline stage 2: Processing logic (pure combinational)
    wire [1:0] proc_out;
    assign proc_out = {in_reg[3], ^in_reg[2:0]};

    // Pipeline stage 3: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out <= 2'b0;
        end else begin
            out <= proc_out;
        end
    end

endmodule