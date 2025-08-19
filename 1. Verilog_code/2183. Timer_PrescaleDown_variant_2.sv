//SystemVerilog
module Timer_PrescaleDown #(parameter DIV=16) (
    input clk, rst_n, load_en,
    input [7:0] init_val,
    output reg timeup
);
    reg [7:0] counter;
    reg [$clog2(DIV)-1:0] ps_cnt;
    
    // Moved timeup_pre closer to input logic
    // and redistributed pipeline registers
    reg timeup_pre;
    reg load_en_r;
    reg [7:0] init_val_r;
    
    // Register inputs to improve timing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_en_r <= 1'b0;
            init_val_r <= 8'h0;
        end else begin
            load_en_r <= load_en;
            init_val_r <= init_val;
        end
    end
    
    // Main counter logic - consolidated
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ps_cnt <= 0;
            counter <= 0;
            timeup_pre <= 1'b0;
        end else begin
            ps_cnt <= (ps_cnt == DIV-1) ? 0 : ps_cnt + 1;
            
            if (load_en_r) 
                counter <= init_val_r;
            else if (ps_cnt == 0 && counter > 0)
                counter <= counter - 1;
                
            // Moved timeup_pre detection earlier in the pipeline
            timeup_pre <= (load_en_r) ? (init_val_r == 0) : 
                          ((ps_cnt == 0 && counter == 1) || (counter == 0 && ps_cnt != 0));
        end
    end
    
    // Final output stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timeup <= 1'b0;
        end else begin
            timeup <= timeup_pre;
        end
    end
endmodule