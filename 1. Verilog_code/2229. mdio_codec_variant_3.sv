//SystemVerilog
module mdio_codec (
    input wire clk, rst_n,
    input wire mdio_in, start_op,
    input wire read_mode,
    input wire [4:0] phy_addr,
    input wire [4:0] reg_addr, 
    input wire [15:0] wr_data,
    output reg mdio_out, mdio_oe,
    output reg [15:0] rd_data,
    output reg busy, data_valid
);
    localparam IDLE=0, START=1, OP=2, PHY_ADDR=3, REG_ADDR=4, TA=5, DATA=6;
    reg [2:0] state;
    reg [5:0] bit_count;
    reg [31:0] shift_reg; // Holds the frame to be transmitted
    
    // 前向寄存器用于暂存输入信号
    reg start_op_r;
    reg read_mode_r;
    reg [4:0] phy_addr_r;
    reg [4:0] reg_addr_r;
    reg [15:0] wr_data_r;
    
    // 输入信号的前级缓存，扁平化if-else结构
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            start_op_r <= 1'b0;
            read_mode_r <= 1'b0;
            phy_addr_r <= 5'b0;
            reg_addr_r <= 5'b0;
            wr_data_r <= 16'b0;
        end else begin
            start_op_r <= start_op;
            read_mode_r <= read_mode;
            phy_addr_r <= phy_addr;
            reg_addr_r <= reg_addr;
            wr_data_r <= wr_data;
        end
    end
    
    // 主状态机逻辑，使用扁平化if-else结构
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE; 
            mdio_out <= 1'b1; 
            mdio_oe <= 1'b0; 
            busy <= 1'b0; 
            data_valid <= 1'b0;
            shift_reg <= 32'b0;
            bit_count <= 6'b0;
        end else if (state == IDLE && start_op_r) begin
            shift_reg <= {2'b01, read_mode_r ? 2'b10 : 2'b01, phy_addr_r, reg_addr_r, 
                         read_mode_r ? 16'h0 : wr_data_r};
            state <= START; 
            bit_count <= 0; 
            busy <= 1'b1; 
            mdio_oe <= 1'b1;
        end else if (state == START) begin
            // START状态处理逻辑
            // 这里添加START状态的具体逻辑
            state <= OP;
            mdio_out <= shift_reg[31];
            shift_reg <= {shift_reg[30:0], 1'b0};
        end else if (state == OP) begin
            // OP状态处理逻辑
            bit_count <= bit_count + 1'b1;
            mdio_out <= shift_reg[31];
            shift_reg <= {shift_reg[30:0], 1'b0};
            if (bit_count == 1) begin
                state <= PHY_ADDR;
                bit_count <= 0;
            end
        end else if (state == PHY_ADDR) begin
            // PHY_ADDR状态处理逻辑
            bit_count <= bit_count + 1'b1;
            mdio_out <= shift_reg[31];
            shift_reg <= {shift_reg[30:0], 1'b0};
            if (bit_count == 4) begin
                state <= REG_ADDR;
                bit_count <= 0;
            end
        end else if (state == REG_ADDR) begin
            // REG_ADDR状态处理逻辑
            bit_count <= bit_count + 1'b1;
            mdio_out <= shift_reg[31];
            shift_reg <= {shift_reg[30:0], 1'b0};
            if (bit_count == 4) begin
                state <= TA;
                bit_count <= 0;
            end
        end else if (state == TA) begin
            // TA状态处理逻辑
            bit_count <= bit_count + 1'b1;
            if (read_mode_r) begin
                mdio_oe <= bit_count == 0 ? 1'b1 : 1'b0;
                mdio_out <= bit_count == 0 ? 1'b1 : 1'b0;
            end else begin
                mdio_out <= shift_reg[31];
                shift_reg <= {shift_reg[30:0], 1'b0};
            end
            if (bit_count == 1) begin
                state <= DATA;
                bit_count <= 0;
                rd_data <= 16'h0;
            end
        end else if (state == DATA && read_mode_r) begin
            // DATA状态读取处理逻辑
            bit_count <= bit_count + 1'b1;
            rd_data <= {rd_data[14:0], mdio_in};
            if (bit_count == 15) begin
                state <= IDLE;
                busy <= 1'b0;
                data_valid <= 1'b1;
            end
        end else if (state == DATA && !read_mode_r) begin
            // DATA状态写入处理逻辑
            bit_count <= bit_count + 1'b1;
            mdio_out <= shift_reg[31];
            shift_reg <= {shift_reg[30:0], 1'b0};
            if (bit_count == 15) begin
                state <= IDLE;
                busy <= 1'b0;
                mdio_oe <= 1'b0;
            end
        end else begin
            // 默认处理逻辑
            data_valid <= 1'b0;
        end
    end
endmodule