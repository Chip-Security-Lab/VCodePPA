//SystemVerilog
module mem_arbiter(
    input wire clk, rst,
    input wire req1, req2, req3,
    input wire [7:0] addr1, addr2, addr3,
    input wire [7:0] wdata1, wdata2, wdata3,
    input wire wen1, wen2, wen3,
    output reg [7:0] addr_out, wdata_out,
    output reg wen_out, grant1, grant2, grant3
);
    localparam IDLE=3'd0, GRANT1=3'd1, GRANT2=3'd2, GRANT3=3'd3;
    reg [2:0] state, next;
    reg [2:0] state_buf1, state_buf2;
    reg [7:0] addr_out_buf1, addr_out_buf2;
    reg [7:0] wdata_out_buf1, wdata_out_buf2;
    reg wen_out_buf1, wen_out_buf2;
    reg grant1_buf1, grant2_buf1, grant3_buf1;
    
    // State register with buffering
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            state_buf1 <= IDLE;
            state_buf2 <= IDLE;
        end else begin
            state <= next;
            state_buf1 <= state;
            state_buf2 <= state_buf1;
        end
    end
    
    // Next state logic
    always @(*) begin
        case (state)
            IDLE: begin
                if (req1) next = GRANT1;
                else if (req2) next = GRANT2;
                else if (req3) next = GRANT3;
                else next = IDLE;
            end
            GRANT1: begin
                if (!req1) begin
                    if (req2) next = GRANT2;
                    else if (req3) next = GRANT3;
                    else next = IDLE;
                end else next = GRANT1;
            end
            GRANT2: begin
                if (!req2) begin
                    if (req3) next = GRANT3;
                    else if (req1) next = GRANT1;
                    else next = IDLE;
                end else next = GRANT2;
            end
            GRANT3: begin
                if (!req3) begin
                    if (req1) next = GRANT1;
                    else if (req2) next = GRANT2;
                    else next = IDLE;
                end else next = GRANT3;
            end
            default: next = IDLE;
        endcase
    end
    
    // Grant signals with buffering
    always @(posedge clk) begin
        if (rst) begin
            grant1_buf1 <= 1'b0;
            grant2_buf1 <= 1'b0;
            grant3_buf1 <= 1'b0;
            grant1 <= 1'b0;
            grant2 <= 1'b0;
            grant3 <= 1'b0;
        end else begin
            grant1_buf1 <= (state == GRANT1);
            grant2_buf1 <= (state == GRANT2);
            grant3_buf1 <= (state == GRANT3);
            grant1 <= grant1_buf1;
            grant2 <= grant2_buf1;
            grant3 <= grant3_buf1;
        end
    end
    
    // Memory interface signals with buffering
    always @(posedge clk) begin
        if (rst) begin
            addr_out_buf1 <= 8'd0;
            addr_out_buf2 <= 8'd0;
            addr_out <= 8'd0;
            wdata_out_buf1 <= 8'd0;
            wdata_out_buf2 <= 8'd0;
            wdata_out <= 8'd0;
            wen_out_buf1 <= 1'b0;
            wen_out_buf2 <= 1'b0;
            wen_out <= 1'b0;
        end else begin
            case (state)
                GRANT1: begin
                    addr_out_buf1 <= addr1;
                    wdata_out_buf1 <= wdata1;
                    wen_out_buf1 <= wen1;
                end
                GRANT2: begin
                    addr_out_buf1 <= addr2;
                    wdata_out_buf1 <= wdata2;
                    wen_out_buf1 <= wen2;
                end
                GRANT3: begin
                    addr_out_buf1 <= addr3;
                    wdata_out_buf1 <= wdata3;
                    wen_out_buf1 <= wen3;
                end
                default: begin
                    addr_out_buf1 <= 8'd0;
                    wdata_out_buf1 <= 8'd0;
                    wen_out_buf1 <= 1'b0;
                end
            endcase
            addr_out_buf2 <= addr_out_buf1;
            wdata_out_buf2 <= wdata_out_buf1;
            wen_out_buf2 <= wen_out_buf1;
            addr_out <= addr_out_buf2;
            wdata_out <= wdata_out_buf2;
            wen_out <= wen_out_buf2;
        end
    end
endmodule