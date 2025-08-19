//SystemVerilog
module RepeatDetector #(parameter WIN=8) (
    input clk, rst_n,
    input [7:0] data,
    output reg [15:0] code
);
    // Buffered signals for high fan-out
    reg [7:0] data_buf1, data_buf2;
    reg [7:0] history [0:WIN-1];
    reg [7:0] history_buf1 [0:WIN-1];
    reg [7:0] history_buf2 [0:WIN-1];
    reg [3:0] ptr, ptr_buf1, ptr_buf2;
    reg [3:0] next_ptr, next_ptr_buf;
    reg [3:0] p_buf1, p_buf2;
    integer i;

    // 曼彻斯特进位链加法器信号
    wire [3:0] p, g;
    wire [4:0] c;

    initial begin
        ptr = 0;
        for(i=0; i<WIN; i=i+1)
            history[i] = 0;
    end

    // Buffer data input
    always @(posedge clk) begin
        if (!rst_n) begin
            data_buf1 <= 8'b0;
            data_buf2 <= 8'b0;
        end else begin
            data_buf1 <= data;
            data_buf2 <= data_buf1;
        end
    end

    // Buffer history array
    always @(posedge clk) begin
        if (!rst_n) begin
            for(i=0; i<WIN; i=i+1) begin
                history_buf1[i] <= 8'b0;
                history_buf2[i] <= 8'b0;
            end
        end else begin
            for(i=0; i<WIN; i=i+1) begin
                history_buf1[i] <= history[i];
                history_buf2[i] <= history_buf1[i];
            end
        end
    end

    // Buffer ptr
    always @(posedge clk) begin
        if (!rst_n) begin
            ptr_buf1 <= 4'b0;
            ptr_buf2 <= 4'b0;
        end else begin
            ptr_buf1 <= ptr;
            ptr_buf2 <= ptr_buf1;
        end
    end

    // 生成传播和生成信号
    assign p[0] = ptr_buf1[0];
    assign p[1] = ptr_buf1[1]; 
    assign p[2] = ptr_buf1[2];
    assign p[3] = ptr_buf1[3];
    
    assign g[0] = 1'b0;
    assign g[1] = 1'b0;
    assign g[2] = 1'b0;
    assign g[3] = 1'b0;
    
    // Buffer p signals
    always @(posedge clk) begin
        if (!rst_n) begin
            p_buf1 <= 4'b0;
            p_buf2 <= 4'b0;
        end else begin
            p_buf1 <= p;
            p_buf2 <= p_buf1;
        end
    end
    
    // 曼彻斯特进位链计算
    assign c[0] = (ptr_buf2 == WIN-1) ? 1'b1 : 1'b0;
    assign c[1] = g[0] | (p_buf1[0] & c[0]);
    assign c[2] = g[1] | (p_buf1[1] & c[1]);
    assign c[3] = g[2] | (p_buf1[2] & c[2]);
    assign c[4] = g[3] | (p_buf1[3] & c[3]);
    
    // 计算next_ptr
    always @(*) begin
        if(ptr_buf2 == WIN-1)
            next_ptr = 0;
        else begin
            next_ptr[0] = p_buf2[0] ^ c[0];
            next_ptr[1] = p_buf2[1] ^ c[1];
            next_ptr[2] = p_buf2[2] ^ c[2];
            next_ptr[3] = p_buf2[3] ^ c[3];
        end
    end

    // Buffer next_ptr
    always @(posedge clk) begin
        if (!rst_n) begin
            next_ptr_buf <= 4'b0;
        end else begin
            next_ptr_buf <= next_ptr;
        end
    end

    always @(posedge clk) begin
        if(!rst_n) begin
            for(i=0; i<WIN; i=i+1)
                history[i] <= 0;
            ptr <= 0;
            code <= 0;
        end
        else begin
            history[ptr_buf1] <= data_buf1;
            
            if(ptr_buf1 > 0 && data_buf1 == history_buf1[ptr_buf1-1])
                code <= {8'hFF, data_buf1};
            else if(ptr_buf1 == 0 && data_buf1 == history_buf1[WIN-1])
                code <= {8'hFF, data_buf1};
            else
                code <= {8'h00, data_buf1};
                
            ptr <= next_ptr_buf;
        end
    end
endmodule