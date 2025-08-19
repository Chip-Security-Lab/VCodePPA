//SystemVerilog
module i2c_prog_timing_master #(
    parameter DEFAULT_PRESCALER = 16'd100
)(
    input  wire        clk,
    input  wire        reset_n,
    input  wire [15:0] scl_prescaler,
    input  wire [7:0]  tx_data,
    input  wire [6:0]  slave_addr,
    input  wire        start_tx,
    output reg         tx_done,
    inout  wire        scl,
    inout  wire        sda
);

    // ------ 状态定义和流水线控制 ------
    localparam IDLE     = 4'd0,
               START    = 4'd1,
               ADDR     = 4'd2,
               ADDR_ACK = 4'd3,
               DATA     = 4'd4,
               DATA_ACK = 4'd5,
               STOP     = 4'd6;
               
    reg [3:0]  state, next_state;
    reg [3:0]  bit_counter;
    reg [7:0]  tx_data_reg;
    reg [6:0]  slave_addr_reg;
    
    // ------ 时钟分频和时序控制 ------
    reg [15:0] clk_div_count;
    reg [15:0] active_prescaler;
    reg        scl_clk;
    reg        scl_phase;
    
    // ------ I2C 输出控制 ------
    reg        scl_int, sda_int;
    reg        scl_oe, sda_oe;
    reg        sda_in_sample;
    
    // ------ 数据通路寄存器 ------
    reg        data_valid;
    reg        tx_started;
    reg        tx_complete;
    
    // ------ I2C 总线控制逻辑 ------
    assign scl = scl_oe ? scl_int : 1'bz;
    assign sda = sda_oe ? sda_int : 1'bz;
    
    // ------ 合并的时序逻辑 ------
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            // 时钟分频器复位
            clk_div_count <= 16'd0;
            scl_clk <= 1'b0;
            scl_phase <= 1'b0;
            
            // 预分频器选择逻辑复位
            active_prescaler <= DEFAULT_PRESCALER;
            
            // 数据寄存流水线复位
            tx_data_reg <= 8'd0;
            slave_addr_reg <= 7'd0;
            data_valid <= 1'b0;
            
            // 状态机控制复位
            state <= IDLE;
            bit_counter <= 4'd0;
            tx_started <= 1'b0;
            tx_complete <= 1'b0;
            
            // I2C 输出控制逻辑复位
            scl_int <= 1'b1;
            sda_int <= 1'b1;
            scl_oe <= 1'b1;
            sda_oe <= 1'b1;
            sda_in_sample <= 1'b1;
            
            // 完成状态指示复位
            tx_done <= 1'b0;
        end 
        else begin
            // 时钟分频器逻辑
            if (clk_div_count >= active_prescaler - 1'b1) begin
                clk_div_count <= 16'd0;
                scl_clk <= ~scl_clk;
                if (scl_clk) scl_phase <= ~scl_phase;
            end else begin
                clk_div_count <= clk_div_count + 1'b1;
            end
            
            // 预分频器选择逻辑
            if (state == IDLE && start_tx) begin
                active_prescaler <= (scl_prescaler == 16'd0) ? DEFAULT_PRESCALER : scl_prescaler;
            end
            
            // 数据寄存流水线
            if (state == IDLE && start_tx) begin
                tx_data_reg <= tx_data;
                slave_addr_reg <= slave_addr;
                data_valid <= 1'b1;
            end else if (state == STOP) begin
                data_valid <= 1'b0;
            end
            
            // 状态机控制
            state <= next_state;
            
            case (state)
                IDLE: begin
                    if (start_tx) begin
                        tx_started <= 1'b1;
                        tx_complete <= 1'b0;
                    end
                end
                
                ADDR: begin
                    if (scl_clk && scl_phase) begin
                        if (bit_counter < 4'd7)
                            bit_counter <= bit_counter + 1'b1;
                    end
                end
                
                DATA: begin
                    if (scl_clk && scl_phase) begin
                        if (bit_counter < 4'd7)
                            bit_counter <= bit_counter + 1'b1;
                    end
                end
                
                STOP: begin
                    bit_counter <= 4'd0;
                    tx_started <= 1'b0;
                    tx_complete <= 1'b1;
                end
                
                default: begin
                    if (scl_clk && !scl_phase) begin
                        bit_counter <= 4'd0;
                    end
                end
            endcase
            
            // I2C 输出控制逻辑
            case (state)
                IDLE: begin
                    scl_int <= 1'b1;
                    sda_int <= 1'b1;
                    scl_oe <= 1'b1;
                    sda_oe <= 1'b1;
                end
                
                START: begin
                    scl_int <= scl_clk;
                    sda_int <= scl_phase ? 1'b0 : 1'b1;
                    scl_oe <= 1'b1;
                    sda_oe <= 1'b1;
                end
                
                ADDR: begin
                    scl_int <= scl_clk;
                    sda_int <= slave_addr_reg[4'd6 - bit_counter];
                    scl_oe <= 1'b1;
                    sda_oe <= 1'b1;
                end
                
                ADDR_ACK: begin
                    scl_int <= scl_clk;
                    sda_int <= 1'b0;
                    scl_oe <= 1'b1;
                    sda_oe <= 1'b0;
                    if (scl_clk && scl_phase)
                        sda_in_sample <= sda;
                end
                
                DATA: begin
                    scl_int <= scl_clk;
                    sda_int <= tx_data_reg[4'd7 - bit_counter];
                    scl_oe <= 1'b1;
                    sda_oe <= 1'b1;
                end
                
                DATA_ACK: begin
                    scl_int <= scl_clk;
                    sda_int <= 1'b0;
                    scl_oe <= 1'b1;
                    sda_oe <= 1'b0;
                    if (scl_clk && scl_phase)
                        sda_in_sample <= sda;
                end
                
                STOP: begin
                    scl_int <= 1'b1;
                    sda_int <= scl_phase ? 1'b1 : 1'b0;
                    scl_oe <= 1'b1;
                    sda_oe <= 1'b1;
                end
                
                default: begin
                    scl_int <= 1'b1;
                    sda_int <= 1'b1;
                    scl_oe <= 1'b1;
                    sda_oe <= 1'b1;
                end
            endcase
            
            // 完成状态指示
            tx_done <= tx_complete;
        end
    end
    
    // ------ 下一状态逻辑 ------
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (tx_started)
                    next_state = START;
            end
            
            START: begin
                if (scl_clk && !scl_phase)
                    next_state = ADDR;
            end
            
            ADDR: begin
                if (scl_clk && !scl_phase && bit_counter == 4'd7)
                    next_state = ADDR_ACK;
            end
            
            ADDR_ACK: begin
                if (scl_clk && !scl_phase)
                    next_state = DATA;
            end
            
            DATA: begin
                if (scl_clk && !scl_phase && bit_counter == 4'd7)
                    next_state = DATA_ACK;
            end
            
            DATA_ACK: begin
                if (scl_clk && !scl_phase)
                    next_state = STOP;
            end
            
            STOP: begin
                if (scl_clk && scl_phase)
                    next_state = IDLE;
            end
            
            default: next_state = IDLE;
        endcase
    end

endmodule