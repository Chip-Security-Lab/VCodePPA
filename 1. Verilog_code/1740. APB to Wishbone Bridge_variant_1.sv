//SystemVerilog
module apb2wb_bridge #(parameter WIDTH=32) (
    input clk, rst_n,
    // APB interface
    input [WIDTH-1:0] apb_paddr, apb_pwdata,
    input apb_pwrite, apb_psel, apb_penable,
    output reg [WIDTH-1:0] apb_prdata,
    output reg apb_pready,
    // Wishbone interface
    output reg [WIDTH-1:0] wb_adr, wb_dat_o,
    output reg wb_we, wb_cyc, wb_stb,
    input [WIDTH-1:0] wb_dat_i,
    input wb_ack
);
    // 定义状态编码
    localparam IDLE = 2'b00;
    localparam SETUP = 2'b01;
    localparam ACCESS = 2'b10;
    localparam WAIT = 2'b11;
    
    reg [1:0] state, next_state;
    
    // 状态寄存器
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // 组合逻辑状态转换和输出控制
    always @(*) begin
        // 默认值
        next_state = state;
        
        case (state)
            IDLE: begin
                if (apb_psel && !apb_penable)
                    next_state = SETUP;
            end
            
            SETUP: begin
                if (apb_psel && apb_penable)
                    next_state = ACCESS;
            end
            
            ACCESS: begin
                if (wb_ack)
                    next_state = WAIT;
            end
            
            WAIT: begin
                if (!apb_psel || !apb_penable)
                    next_state = IDLE;
            end
        endcase
    end
    
    // 数据路径和输出控制
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wb_cyc <= 1'b0;
            wb_stb <= 1'b0;
            apb_pready <= 1'b0;
            wb_adr <= {WIDTH{1'b0}};
            wb_we <= 1'b0;
            wb_dat_o <= {WIDTH{1'b0}};
            apb_prdata <= {WIDTH{1'b0}};
        end
        else begin
            case (state)
                IDLE: begin
                    wb_cyc <= 1'b0;
                    wb_stb <= 1'b0;
                    apb_pready <= 1'b0;
                    
                    if (apb_psel && !apb_penable) begin
                        wb_adr <= apb_paddr;
                        wb_we <= apb_pwrite;
                        if (apb_pwrite)
                            wb_dat_o <= apb_pwdata;
                    end
                end
                
                SETUP: begin
                    if (apb_psel && apb_penable) begin
                        wb_cyc <= 1'b1;
                        wb_stb <= 1'b1;
                    end
                end
                
                ACCESS: begin
                    if (wb_ack) begin
                        wb_cyc <= 1'b0;
                        wb_stb <= 1'b0;
                        if (!wb_we)
                            apb_prdata <= wb_dat_i;
                        apb_pready <= 1'b1;
                    end
                end
                
                WAIT: begin
                    if (!apb_psel || !apb_penable)
                        apb_pready <= 1'b0;
                end
            endcase
        end
    end
endmodule