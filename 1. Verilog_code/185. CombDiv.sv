module CombDiv(
    input [3:0] D, d,
    output [3:0] q
);
    reg [3:0] cnt;
    reg [7:0] acc;
    
    always @(*) begin
        // Initialize at each evaluation
        cnt = 0;
        acc = D;
        
        // Use if-else cascade instead of while loop
        if(acc >= d && d != 0) begin
            acc = acc - d;
            cnt = cnt + 1;
            
            if(acc >= d) begin
                acc = acc - d;
                cnt = cnt + 1;
                
                if(acc >= d) begin
                    acc = acc - d;
                    cnt = cnt + 1;
                    
                    if(acc >= d) begin
                        acc = acc - d;
                        cnt = cnt + 1;
                        
                        if(acc >= d) begin
                            acc = acc - d;
                            cnt = cnt + 1;
                            
                            if(acc >= d) begin
                                acc = acc - d;
                                cnt = cnt + 1;
                                
                                if(acc >= d) begin
                                    acc = acc - d;
                                    cnt = cnt + 1;
                                    
                                    if(acc >= d) begin
                                        acc = acc - d;
                                        cnt = cnt + 1;
                                        
                                        if(acc >= d) begin
                                            acc = acc - d;
                                            cnt = cnt + 1;
                                            
                                            if(acc >= d) begin
                                                acc = acc - d;
                                                cnt = cnt + 1;
                                                
                                                if(acc >= d) begin
                                                    acc = acc - d;
                                                    cnt = cnt + 1;
                                                    
                                                    if(acc >= d) begin
                                                        acc = acc - d;
                                                        cnt = cnt + 1;
                                                        
                                                        if(acc >= d) begin
                                                            acc = acc - d;
                                                            cnt = cnt + 1;
                                                            
                                                            if(acc >= d) begin
                                                                acc = acc - d;
                                                                cnt = cnt + 1;
                                                                
                                                                if(acc >= d) begin
                                                                    acc = acc - d;
                                                                    cnt = cnt + 1;
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    
    assign q = cnt;
endmodule