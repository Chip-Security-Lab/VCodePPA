module timeout_buf #(parameter DW=8, TIMEOUT=100) (
    input clk, rst_n,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output [DW-1:0] dout,
    output valid
);
    reg [DW-1:0] data_reg;
    reg [15:0] timer;
    reg valid_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            valid_reg <= 0;
            timer <= 0;
            data_reg <= 0;
        end else begin
            if(wr_en) begin
                data_reg <= din;
                valid_reg <= 1;
                timer <= 0;
            end
            else if(valid_reg) begin
                if(timer < TIMEOUT)
                    timer <= timer + 1;
                else
                    valid_reg <= 0;
            end
            if(rd_en && valid_reg) valid_reg <= 0;
        end
    end
    assign dout = data_reg;
    assign valid = valid_reg;
endmodule