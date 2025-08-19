module watchdog_buf #(parameter DW=8, TIMEOUT=1000) (
    input clk, rst_n,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output reg [DW-1:0] dout,
    output reg error
);
    reg [DW-1:0] buf_reg;
    reg [15:0] counter=0;
    reg valid=0;
    
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            valid <= 0;
            counter <= 0;
            error <= 0;
        end
        else begin
            if(wr_en) begin
                buf_reg <= din;
                valid <= 1;
                counter <= 0;
                error <= 0;
            end
            else if(valid) begin
                counter <= counter + (counter < TIMEOUT);
                if(counter >= TIMEOUT) begin
                    error <= 1;
                    valid <= 0;
                end
            end
            if(rd_en && valid) begin
                dout <= buf_reg;
                valid <= 0;
                error <= 0;
                counter <= 0;
            end
        end
    end
endmodule
